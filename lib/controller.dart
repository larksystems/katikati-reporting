library controller;

import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/logger.dart';

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link('analyse', 'Analyse', handleNavToAnalysis),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';
const UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG = 'Unable to fetch interactions';

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
int _selectedAnalysisTabIndex;
bool _dataComparisonEnabled = true;
bool _dataNormalisationEnabled = false;
Set<String> _activeFilters = {};
Map<String, String> _filterValues = {};
Map<String, String> _comparisonFilterValues = {};

// Data states
Map<String, Map<String, dynamic>> _allInteractions;
Map<String, Set> _uniqueFieldCategoryValues;
model.Config _config;

// Actions
enum UIAction {
  signinWithGoogle,
  changeNavTab,
  changeAnalysisTab,
  toggleDataComparison,
  toggleDataNormalisation,
  toggleActiveFilter,
  setFilterValue,
  setComparisonFilterValue
}

// Action data
class Data {}

class NavChangeData extends Data {
  String pathname;
  NavChangeData(this.pathname);
}

class AnalysisTabChangeData extends Data {
  int tabIndex;
  AnalysisTabChangeData(this.tabIndex);
}

class ToggleOptionEnabledData extends Data {
  bool enabled;
  ToggleOptionEnabledData(this.enabled);
}

class ToggleActiveFilterData extends Data {
  String key;
  bool enabled;
  ToggleActiveFilterData(this.key, this.enabled);
}

class SetFilterValueData extends Data {
  String key;
  String value;
  SetFilterValueData(this.key, this.value);
}

// Controller functions
void init() async {
  view.init();
  view.showLoginModal();
  _navLinks.forEach((_, n) {
    view.appendNavLink(n.pathname, n.label, _currentNavLink == n.pathname);
  });

  await fb.init(
      'assets/firebase-constants.json', onLoginCompleted, onLogoutCompleted);
}

// Login, logout, load data
void onLoginCompleted() async {
  view.showLoading();

  await loadDataFromFirebase();
  _uniqueFieldCategoryValues =
      computeUniqFieldCategoryValues(_config.filters, _allInteractions);
  _selectedAnalysisTabIndex = 0;

  view.setNavlinkSelected(_currentNavLink);
  _navLinks[_currentNavLink].render();

  view.hideLoading();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
}

void loadDataFromFirebase() async {
  try {
    _config = await fb.fetchConfig();
  } catch (e) {
    view.showAlert(UNABLE_TO_PARSE_CONFIG_ERROR_MSG);
    logger.error(e);
    rethrow;
  }

  try {
    _allInteractions =
        await fb.fetchInteractions(_config.data_paths['interactions']);
  } catch (e) {
    view.showAlert(UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG);
    logger.error(e);
    rethrow;
  }
}

// Compute data methods
Map<String, Set> computeUniqFieldCategoryValues(
    List<model.Filter> filterOptions,
    Map<String, Map<String, dynamic>> interactions) {
  var uniqueFieldCategories = Map<String, Set>();
  filterOptions.forEach((option) {
    uniqueFieldCategories[option.key] = Set();
  });

  interactions.forEach((_, interaction) {
    uniqueFieldCategories.forEach((key, valueSet) {
      var value = interaction[key];
      (value is List) ? valueSet.addAll(value) : valueSet.add(value);
    });
  });

  logger.debug('Computed unique field values for all filters');
  return uniqueFieldCategories;
}

bool _interactionMatchesFilters(
    Map<String, dynamic> interaction, Map<String, String> filters) {
  for (var entry in filters.entries) {
    var interactionValue = interaction[entry.key];
    var interactionMatch = interactionValue is List
        ? interactionValue.contains(entry.value)
        : interactionValue == entry.value;

    if (!interactionMatch) {
      return false;
    }
  }

  return true;
}

bool _interactionMatchesOperation(
    Map<String, dynamic> interaction, model.Field chartCol) {
  switch (chartCol.field.operator) {
    case model.FieldOperator.equals:
      if (interaction[chartCol.field.key] == chartCol.field.value) {
        return true;
      }
      break;
    case model.FieldOperator.contains:
      if ((interaction[chartCol.field.key] as List)
          .contains(chartCol.field.value)) {
        return true;
      }
      break;
    case model.FieldOperator.not_contains:
      if (!(interaction[chartCol.field.key] as List)
          .contains(chartCol.field.value)) {
        return true;
      }
      break;
    default:
      logger.error('No such operator, misleading results');
      view.showAlert(
          'Operator ${chartCol.field.operator} is not handled in your config!');
  }
  return false;
}

void _computeChartBuckets(List<model.Chart> charts) {
  // reset bucket to [filter(0), comparisonFilter(0)] for each chart
  for (var chart in charts) {
    for (var chartCol in chart.fields) {
      chartCol.bucket = [0, 0];
    }
  }

  // Consider only active filters from filter values
  var activeFilterValues = {..._filterValues}
    ..removeWhere((key, _) => !_activeFilters.contains(key));
  var activeComparisonFilterValues = {..._comparisonFilterValues}
    ..removeWhere((key, _) => !_activeFilters.contains(key));

  for (var interaction in _allInteractions.values) {
    // Check if this interaction falls within the active filter
    var addToPrimaryBucket =
        _interactionMatchesFilters(interaction, activeFilterValues);
    var addToComparisonBucket =
        _interactionMatchesFilters(interaction, activeComparisonFilterValues);

    // If the interaction doesnt fall in the active filters, continue
    if (!addToPrimaryBucket && !addToComparisonBucket) continue;

    for (var chart in charts) {
      for (var chartCol in chart.fields) {
        if (!_interactionMatchesOperation(interaction, chartCol)) continue;

        if (addToPrimaryBucket) {
          ++chartCol.bucket[0];
        }
        if (addToComparisonBucket) {
          ++chartCol.bucket[1];
        }
      }
    }
  }

  logger.debug('Computed chart buckets ${charts}');
}

// Render methods
void handleNavToAnalysis() {
  view.clearContentTab();
  var tabLabels =
      _config.tabs.asMap().map((i, t) => MapEntry(i, t.label)).values.toList();
  view.renderAnalysisTabs(tabLabels);
  view.renderChartOptions(_dataComparisonEnabled, _dataNormalisationEnabled);

  var filterKeys = _config.filters.map((filter) => filter.key).toList();
  filterKeys.removeWhere((filter) =>
      _config.tabs[_selectedAnalysisTabIndex].exclude_filters.contains(filter));
  var filterOptions = _uniqueFieldCategoryValues.map((key, setValues) {
    return MapEntry(
        key, setValues.map((s) => s.toString()).toList()..add('__all'));
  });

  view.renderFilterDropdowns(filterKeys, filterOptions, _dataComparisonEnabled);

  _computeChartBuckets(_config.tabs[_selectedAnalysisTabIndex].charts);
}

void handleNavToSettings() {
  view.clearContentTab();
  // todo: replace with actual contents for settings tab
  view.renderSettingsTab();
}

// User actions
void command(UIAction action, Data data) {
  switch (action) {
    case UIAction.signinWithGoogle:
      fb.signInWithGoogle();
      break;
    case UIAction.changeNavTab:
      var d = data as NavChangeData;
      _currentNavLink = d.pathname;
      view.setNavlinkSelected(_currentNavLink);
      _navLinks[_currentNavLink].render();
      break;
    case UIAction.changeAnalysisTab:
      var d = data as AnalysisTabChangeData;
      _selectedAnalysisTabIndex = d.tabIndex;
      logger.debug('Changed to analysis tab ${_selectedAnalysisTabIndex}');
      // todo: handle switch between analysis tabs
      break;
    case UIAction.toggleDataComparison:
      var d = data as ToggleOptionEnabledData;
      _dataComparisonEnabled = d.enabled;
      logger.debug('Data comparison changed to ${_dataComparisonEnabled}');
      // todo: handle for data comparison
      break;
    case UIAction.toggleDataNormalisation:
      var d = data as ToggleOptionEnabledData;
      _dataNormalisationEnabled = d.enabled;
      logger
          .debug('Data normalisation changed to ${_dataNormalisationEnabled}');
      // todo: handle for data normalisation
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      if (d.enabled) {
        _activeFilters.add(d.key);
        logger.debug('Added ${d.key} to active filters, ${_activeFilters}');
      } else {
        _activeFilters.removeWhere((filter) => filter == d.key);
        logger.debug('Removed ${d.key} from active filters, ${_activeFilters}');
      }
      // todo: handle for changes in active filter
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      _filterValues[d.key] = d.value;
      logger.debug('Set to filter values, ${_filterValues}');
      // todo: handle for filter changes
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      _comparisonFilterValues[d.key] = d.value;
      logger
          .debug('Set to comparison filter values, ${_comparisonFilterValues}');
      // todo: handle for filter compare changes
      break;
    default:
  }
}
