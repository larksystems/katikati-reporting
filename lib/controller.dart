library controller;

import 'dart:convert' as convert;
import 'dart:html' as html;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/chart_helpers.dart' as chart_helper;
import 'package:dashboard/logger.dart';

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link('analyse', 'Analyse', handleNavToAnalysis),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

const DEFAULT_FILTER_SELECT_VALUE = '__all';

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
int _filterValuesCount = 0;
int _comparisonFilterValuesCount = 0;
Map<String, Map<model.GeoRegionLevel, dynamic>> _mapsGeoJSON = {};

Map<String, String> get _activeFilterValues =>
    {..._filterValues}..removeWhere((key, _) => !_activeFilters.contains(key));
Map<String, String> get _activeComparisonFilterValues => {
      ..._comparisonFilterValues
    }..removeWhere((key, _) => !_activeFilters.contains(key));

// Data states
Map<String, Map<String, dynamic>> _allInteractions;
Map<String, Set> _uniqueFieldCategoryValues;
Map<String, dynamic> _configRaw;
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
  setComparisonFilterValue,
  saveConfigToFirebase
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

class SaveConfigToFirebaseData extends Data {
  String configRaw;
  SaveConfigToFirebaseData(this.configRaw);
}

// Controller functions
void init() async {
  view.init();
  view.showLoginModal();
  _navLinks.forEach((_, n) {
    view.appendNavLink(n.pathname, n.label, _currentNavLink == n.pathname);
  });

  await fb.init('assets/constants.json', onLoginCompleted, onLogoutCompleted);
}

// Login, logout, load data
void onLoginCompleted() async {
  view.showLoading();

  await loadFirebaseData();
  await loadGeoMapsData();
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

void loadFirebaseData() async {
  try {
    _configRaw = await fb.fetchConfig();
    _config = model.Config.fromData(_configRaw);
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

void loadGeoMapsData() async {
  for (var tab in _config.tabs) {
    for (var chart in tab.charts) {
      if (chart.type == model.ChartType.map) {
        var country = chart.geography.country;
        var regionLevel = chart.geography.regionLevel;
        var regionLevelStr = regionLevel.toString().split('.').last;
        var mapPath = 'assets/maps/${country}/${regionLevelStr}.geojson';
        var geostr;
        try {
          geostr = await html.HttpRequest.getString(mapPath);
        } catch (e) {
          view.showAlert(
              'Failed to get geography map ${country}/${regionLevelStr}');
          rethrow;
        }

        var geojson = convert.jsonDecode(geostr);

        _mapsGeoJSON[country] = _mapsGeoJSON[country] ?? {};
        _mapsGeoJSON[country][regionLevel] = geojson;
      }
    }
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
      logger.error('No such operator: ${chartCol.field.operator}');
      view.showAlert(
          'Warning: Field operator ${chartCol.field.operator} listed in your config is not supported. Results may be misleading');
  }
  return false;
}

void _computeChartBuckets(List<model.Chart> charts) {
  _filterValuesCount = 0;
  _comparisonFilterValuesCount = 0;

  // reset bucket to [filter(0), comparisonFilter(0)] for each chart
  for (var chart in charts) {
    for (var chartCol in chart.fields) {
      chartCol.bucket = [0, 0];
    }
  }

  for (var interaction in _allInteractions.values) {
    // Check if this interaction falls within the active filter
    var addToPrimaryBucket =
        _interactionMatchesFilters(interaction, _activeFilterValues);
    var addToComparisonBucket =
        _interactionMatchesFilters(interaction, _activeComparisonFilterValues);

    if (addToPrimaryBucket) {
      ++_filterValuesCount;
    }

    if (addToComparisonBucket) {
      ++_comparisonFilterValuesCount;
    }

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
  _selectedAnalysisTabIndex = 0;
  _activeFilters = {};
  _filterValues = {};
  _comparisonFilterValues = {};

  var tabLabels =
      _config.tabs.asMap().map((i, t) => MapEntry(i, t.label)).values.toList();
  view.renderAnalysisTabs(tabLabels);
  view.renderChartOptions(_dataComparisonEnabled, _dataNormalisationEnabled);

  _computeFilterDropdownsAndRender();
  _computeChartBucketsAndRender();
}

void _computeFilterDropdownsAndRender() {
  var filterKeys = _config.filters.map((filter) => filter.key).toList();
  var filterOptions = _uniqueFieldCategoryValues.map((key, setValues) {
    return MapEntry(
        key,
        setValues.map((s) => s.toString()).toList()
          ..add(DEFAULT_FILTER_SELECT_VALUE));
  });

  var initialFilterValues = {
    for (var key in filterKeys) key: DEFAULT_FILTER_SELECT_VALUE
  };

  view.renderFilterDropdowns(filterKeys, filterOptions, _activeFilters,
      initialFilterValues, initialFilterValues, _dataComparisonEnabled);

  var selectedTab = _config.tabs[_selectedAnalysisTabIndex];
  for (var filterKey in selectedTab.exclude_filters ?? []) {
    view.hideFilterRow(filterKey);
  }
}

void _computeChartBucketsAndRender() {
  var charts = _config.tabs[_selectedAnalysisTabIndex].charts;
  _computeChartBuckets(charts);

  for (var chart in charts) {
    switch (chart.type) {
      case model.ChartType.bar:
        view.renderBarChart(
            chart.title,
            chart.narrative,
            chart_helper.generateBarChartConfig(chart, _dataComparisonEnabled,
                _activeFilterValues, _activeComparisonFilterValues));
        break;
      case model.ChartType.map:
        var mapData =
            _mapsGeoJSON[chart.geography.country][chart.geography.regionLevel];
        var mapValues = Map<String, List<num>>();
        var mapComparisonValues = Map<String, List<num>>();
        for (var field in chart.fields) {
          var regionName = field.field.value.toString();
          mapValues[regionName] = [
            field.bucket[0],
            field.bucket[0] / _filterValuesCount,
          ];
          mapComparisonValues[regionName] = [
            field.bucket[1],
            field.bucket[1] / _comparisonFilterValuesCount
          ];
        }

        view.renderGeoMap(
          chart.title,
          chart.narrative,
          mapData,
          mapValues,
          mapComparisonValues,
          _dataComparisonEnabled,
          chart.colors ?? chart_helper.barChartDefaultColors,
        );
        break;
      default:
        logger.error('No such chart type ${chart.type}');
        view.showAlert(
            'Warning: Chart type ${chart.type} listed in your config is not supported.');
    }
  }
}

void handleNavToSettings() {
  view.clearContentTab();
  var encoder = convert.JsonEncoder.withIndent('  ');
  var configString = encoder.convert(_configRaw);
  view.renderSettingsTab(configString);
}

void _updateFiltersInView() {
  var filterKeys = _config.filters.map((filter) => filter.key).toList();
  var selectedTab = _config.tabs[_selectedAnalysisTabIndex];
  var excludeKeys = selectedTab.exclude_filters ?? [];
  for (var key in filterKeys) {
    if (!_activeFilters.contains(key)) {
      view.disableFilterOption(key);
      view.disableFilterDropdown(key);
      view.disableFilterDropdown(key, comparison: true);
    } else {
      view.enableFilterOption(key);
      view.enableFilterDropdown(key);
      view.enableFilterDropdown(key, comparison: true);
    }

    view.setFilterDropdownValue(
        key, _filterValues[key] ?? DEFAULT_FILTER_SELECT_VALUE);
    view.setFilterDropdownValue(
        key, _comparisonFilterValues[key] ?? DEFAULT_FILTER_SELECT_VALUE,
        comparison: true);

    if (_dataComparisonEnabled) {
      view.showFilterDropdown(key, comparison: true);
    } else {
      view.hideFilterDropdown(key, comparison: true);
    }

    if (excludeKeys.contains(key)) {
      view.hideFilterRow(key);
    } else {
      view.showFilterRow(key);
    }
  }
}

// User actions
void command(UIAction action, Data data) async {
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
      _activeFilters = {};
      _filterValues = {};
      _comparisonFilterValues = {};
      _updateFiltersInView();
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      logger.debug('Changed to analysis tab ${_selectedAnalysisTabIndex}');
      break;
    case UIAction.toggleDataComparison:
      var d = data as ToggleOptionEnabledData;
      _dataComparisonEnabled = d.enabled;
      _updateFiltersInView();
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      logger.debug('Data comparison changed to ${_dataComparisonEnabled}');
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
        view.enableFilterDropdown(d.key);
        if (_dataComparisonEnabled) {
          view.enableFilterDropdown(d.key, comparison: true);
        }
        logger.debug('Added ${d.key} to active filters, ${_activeFilters}');
      } else {
        _activeFilters.removeWhere((filter) => filter == d.key);
        view.disableFilterDropdown(d.key);
        if (_dataComparisonEnabled) {
          view.disableFilterDropdown(d.key, comparison: true);
        }
        logger.debug('Removed ${d.key} from active filters, ${_activeFilters}');
      }
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      _filterValues[d.key] = d.value;
      logger.debug('Set to filter values, ${_filterValues}');
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      _comparisonFilterValues[d.key] = d.value;
      logger
          .debug('Set to comparison filter values, ${_comparisonFilterValues}');
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      break;
    case UIAction.saveConfigToFirebase:
      var d = data as SaveConfigToFirebaseData;
      var configRaw = d.configRaw;
      var configJSON;
      view.hideConfigSettingsAlert();

      try {
        configJSON = convert.jsonDecode(configRaw);
        var config = model.Config.fromData(configJSON);
        validateConfig(config);
      } catch (e) {
        if (e is StateError || e is FormatException) {
          view.showConfigSettingsAlert(e.message, true);
        } else {
          view.showConfigSettingsAlert(e.toString(), true);
        }
        return;
      }

      try {
        await fb.updateConfig(configJSON);
      } catch (e) {
        view.showAlert(e);
        logger.error(e);
        return;
      }

      view.showConfigSettingsAlert('Config saved successfully', false);
      _configRaw = configJSON;
      _config = model.Config.fromData(_configRaw);
      break;
    default:
  }
}

void validateConfig(model.Config config) {
  // Data paths
  if (config.data_paths == null) {
    throw StateError('data_paths cannot be empty');
  }

  if (config.data_paths['interactions'] == null) {
    throw StateError('data_paths > interactions cannot be empty');
  }

  // Filters
  if (config.filters == null) {
    throw StateError('filters need to be an array');
  }

  for (var filter in config.filters) {
    if (filter.key == null) {
      throw StateError('filters {key} cannot be empty');
    }
  }

  // Tabs
  if (config.tabs == null) {
    throw StateError('tabs cannot be empty');
  }

  for (var tab in config.tabs) {
    for (var chart in tab.charts) {
      for (var field in chart.fields) {
        if (field.field.key == null) {
          throw StateError('Chart field cannot be empty');
        }
        if (field.field.value == null) {
          throw StateError('Chart field value cannot be empty');
        }
        // no need to check for operator, as it is caught by enums
      }

      // geography map
      if (chart.type == model.ChartType.map) {
        if (chart.geography == null ||
            chart.geography.country == null ||
            chart.geography.regionLevel == null) {
          throw StateError('Geography map not specified');
        }
      }
    }
  }
}
