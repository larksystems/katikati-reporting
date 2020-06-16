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

const _errorMessages = {
  'parse-config': 'Unable to parse "Config" to the required format',
  'fetch-interactions': 'Unable to fetch interactions'
};

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
int _selectedAnalysisTabIndex;
bool _isDataComparisonEnabled = true;
bool _isDataNormalisationEnabled = false;
Set<String> _activeFilters = {};
Map<String, String> _filterValues = {};
Map<String, String> _comparisonFilterValues = {};

// Data states
Map<String, Map<String, dynamic>> _allInteractions;
Map<String, Map<String, dynamic>> _filteredInteractions;
Map<String, Map<String, dynamic>> _filteredComparisonInteractions;
Map<String, Set> _uniqueFieldValues;
model.Config _config;
List<model.Chart> _charts;

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

class ToggleData extends Data {
  bool isEnabled;
  ToggleData(this.isEnabled);
}

class ToggleActiveFilterData extends Data {
  String key;
  bool isActive;
  ToggleActiveFilterData(this.key, this.isActive);
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
  _filteredInteractions = _allInteractions;
  _filteredComparisonInteractions = _allInteractions;

  _uniqueFieldValues =
      computeUniqFieldValues(_config.filters, _allInteractions);
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
    view.showAlert(_errorMessages['parse-config']);
    logger.error(e);
    rethrow;
  }

  try {
    _allInteractions =
        await fb.fetchInteractions(_config.data_paths['interactions']);
  } catch (e) {
    view.showAlert(_errorMessages['fetch-interactions']);
    logger.error(e);
    rethrow;
  }
}

// Compute data methods
Map<String, Set> computeUniqFieldValues(List<model.Filter> filterOptions,
    Map<String, Map<String, dynamic>> interactions) {
  var uniqueFieldValues = Map<String, Set>();
  filterOptions.forEach((option) {
    uniqueFieldValues[option.key] = Set();
  });

  interactions.forEach((_, interaction) {
    uniqueFieldValues.forEach((key, valueSet) {
      var value = interaction[key];
      (value is List) ? valueSet.addAll(value) : valueSet.add(value);
    });
  });

  logger.debug('Computed unique field values for all filters');
  return uniqueFieldValues;
}

// Render methods
void handleNavToAnalysis() {
  view.clearContentTab();
  var tabLabels = _config.tabs
      .asMap()
      .map((i, t) => MapEntry(i, t.label ?? 'Tab ${i}'))
      .values
      .toList();
  view.renderAnalysisTabRadio(tabLabels);
  view.renderChartOptions(
      _isDataComparisonEnabled, _isDataNormalisationEnabled);

  var filterKeys = _config.filters.map((filter) => filter.key).toList();
  filterKeys.removeWhere((filter) =>
      _config.tabs[_selectedAnalysisTabIndex].exclude_filters.contains(filter));
  var filterOptions = _uniqueFieldValues.map((key, setValues) {
    return MapEntry(
        key, setValues.map((s) => s.toString()).toList()..add('__all'));
  });

  view.renderFilterDropdowns(
      filterKeys, filterOptions, _isDataComparisonEnabled);
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
      var d = data as ToggleData;
      _isDataComparisonEnabled = d.isEnabled;
      logger.debug('Data comparison changed to ${_isDataComparisonEnabled}');
      // todo: handle for data comparison
      break;
    case UIAction.toggleDataNormalisation:
      var d = data as ToggleData;
      _isDataNormalisationEnabled = d.isEnabled;
      logger.debug(
          'Data normalisation changed to ${_isDataNormalisationEnabled}');
      // todo: handle for data normalisation
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      if (d.isActive) {
        _activeFilters.removeWhere((filter) => filter == d.key);
        logger.debug('Added ${d.key} to active filters');
      } else {
        _activeFilters.add(d.key);
        logger.debug('Removed ${d.key} from active filters');
      }
      // todo: handle for changes in active filter
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      _filterValues[d.key] = d.value;
      logger.debug('Current filters ${_filterValues}');
      // todo: handle for filter changes
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      _comparisonFilterValues[d.key] = d.value;
      logger.debug('Current comparison filters ${_comparisonFilterValues}');
      // todo: handle for filter compare changes
      break;
    default:
  }
}
