library controller;

import 'dart:convert' as convert;
import 'dart:html' as html;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/chart_helpers.dart' as chart_helper;
import 'package:dashboard/extensions.dart';
import 'package:dashboard/logger.dart';
import 'package:firebase/firestore.dart';
import 'package:intl/intl.dart' as intl;

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link(
      'analyse', 'Analyse', () => handleNavToAnalysis(maintainFilters: false)),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

var STANDARD_DATE_TIME_FORMAT = intl.DateFormat('yyyy-MM-dd HH:mm:ss');

const DEFAULT_FILTER_SELECT_VALUE = '__all';

const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';
const UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG = 'Unable to fetch interactions';
const UNABLE_TO_FETCH_SURVEY_STATUS_ERROR_MSG = 'Unable to fetch survey status';

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
int _selectedAnalysisTabIndex = 0;
bool _dataComparisonEnabled = true;
bool _dataNormalisationEnabled = false;
bool _stackTimeSeriesEnabled = true;
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
Map<String, List<DateTime>> _allInteractionsDateRange;
Map<String, Map<model.TimeAggregate, Map<String, num>>>
    _allInteractionDateBuckets;
Map<String, dynamic> _configRaw;
model.Config _config;

Map<String, Map<String, dynamic>> _surveyStatus;

// Actions
enum UIAction {
  signinWithGoogle,
  changeNavTab,
  changeAnalysisTab,
  toggleDataComparison,
  toggleDataNormalisation,
  toggleStackTimeseries,
  toggleActiveFilter,
  setFilterValue,
  setComparisonFilterValue,
  saveConfigToFirebase,
  copyToClipboardConfigSkeleton,
  copyToClipboardChartConfig
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

class CopyToClipboardChartConfigData extends Data {
  String key;
  CopyToClipboardChartConfigData(this.key);
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

  fb.listenToConfig((DocumentSnapshot documentSnapshot) async {
    _configRaw = documentSnapshot.data();
    _config = model.Config.fromData(_configRaw);

    await loadGeoMapsData();
    _handleInteractionsChanges();
    _handleSurveyStatusChanges();
  }, (error) {
    view.showAlert(UNABLE_TO_PARSE_CONFIG_ERROR_MSG);
    logger.error(error.toString());
  });
}

void _handleInteractionsChanges() {
  var interactionsPath = _config.data_paths['interactions'];
  if (interactionsPath != null) {
    fb.listenToInteractions(interactionsPath, (QuerySnapshot querySnapshot) {
      var interactionsMap = Map<String, Map<String, dynamic>>();
      querySnapshot.forEach((doc) {
        interactionsMap[doc.id] = doc.data();
      });
      _allInteractions = interactionsMap;
      _handleDataChanges();
    }, (error) {
      view.showAlert(UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG);
      logger.error(error.toString());
    });
  }
}

void _handleSurveyStatusChanges() {
  var surveyStatusPath = _config.data_paths['survey_status'];
  if (surveyStatusPath != null) {
    fb.listenToSurveyStatus(surveyStatusPath, (QuerySnapshot querySnapshot) {
      var statusMap = Map<String, Map<String, dynamic>>();
      querySnapshot.forEach((doc) {
        statusMap[doc.id] = doc.data();
      });
      _surveyStatus = statusMap;
      _handleDataChanges();
    }, (error) {
      view.showAlert(UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG);
      logger.error(error.toString());
    });
  }
}

void _handleDataChanges() {
  if (_allInteractions == null) return;
  if (_configRaw == null) return;
  if (_config.data_paths['survey_status'] != null && _surveyStatus == null) {
    return;
  }

  view.hideLoading();

  _uniqueFieldCategoryValues =
      computeUniqFieldCategoryValues(_config.filters, _allInteractions);
  _allInteractionsDateRange = computeDateRanges(_allInteractions);

  view.setNavlinkSelected(_currentNavLink);
  if (_navLinks[_currentNavLink].pathname == 'settings') {
    handleNavToSettings();
  } else if (_navLinks[_currentNavLink].pathname == 'analyse') {
    handleNavToAnalysis(maintainFilters: true);
  }

  view.hideLoading();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
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

Map<String, List<DateTime>> computeDateRanges(
    Map<String, Map<String, dynamic>> interactions) {
  var dateRanges = Map<String, List<DateTime>>();
  interactions.forEach((_, interaction) {
    interaction.keys.forEach((key) {
      var value = interaction[key];
      if (value is DateTime) {
        dateRanges[key] = dateRanges[key] ?? [DateTime(2100), DateTime(1970)];
        if (value.isBefore(dateRanges[key][0])) {
          dateRanges[key][0] = value;
        }
        if (value.isAfter(dateRanges[key][1])) {
          dateRanges[key][1] = value;
        }
      }
    });
  });
  logger.debug('Computed date ranges for all interactions');
  return dateRanges;
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

  // reset bucket to [filter(0), comparisonFilter(0)] for each chart col
  // reset time_bucket to {"mm/dd/yyyy": 0} for time series chart col
  // reset allInteractionDateBuckets (for normalising) to {"recorded_at": {day: {"mm/dd/yyyy": 0}}}
  for (var chart in charts) {
    for (var chartCol in chart.fields) {
      chartCol.bucket = [0, 0];
      if (chart.type == model.ChartType.time_series) {
        chartCol.time_bucket = _generateEmptyDateTimeBuckets(
            _allInteractionsDateRange[chart.timestamp.key][0],
            _allInteractionsDateRange[chart.timestamp.key][1],
            chart.timestamp.aggregate);
      }
    }
    if (chart.type == model.ChartType.time_series) {
      var key = chart.timestamp.key;
      var aggregate = chart.timestamp.aggregate;
      _allInteractionDateBuckets = {};
      _allInteractionDateBuckets[key] = {};
      _allInteractionDateBuckets[key][aggregate] =
          _generateEmptyDateTimeBuckets(
              _allInteractionsDateRange[chart.timestamp.key][0],
              _allInteractionsDateRange[chart.timestamp.key][1],
              chart.timestamp.aggregate);
    } else if (chart.type == model.ChartType.funnel) {
      var data = _surveyStatus[chart.fields.first.field.value]
          [chart.fields.first.field.key];
      chart.data = (data as List)
          .map((d) => model.FunnelData(d['label'], d['value']))
          .toList();
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
      for (var chart in charts) {
        if (chart.type == model.ChartType.time_series) {
          var key = chart.timestamp.key;
          var aggregate = chart.timestamp.aggregate;
          var timeStampKey = _generateDateTimeKey(interaction[key], aggregate);
          _allInteractionDateBuckets[key][aggregate][timeStampKey] += 1;
        }
      }
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
          if (chart.type == model.ChartType.time_series) {
            var dateTimeKey = _generateDateTimeKey(
                interaction[chart.timestamp.key] as DateTime,
                chart.timestamp.aggregate);
            chartCol.time_bucket[dateTimeKey] += 1;
          }
        }
        if (addToComparisonBucket) {
          ++chartCol.bucket[1];
        }
      }
    }
  }

  if (_dataNormalisationEnabled) {
    for (var chart in charts) {
      for (var chartCol in chart.fields) {
        num filterValuesPercent = chartCol.bucket[0] * 100 / _filterValuesCount;
        num comparisonFilterValuesPercent =
            chartCol.bucket[1] * 100 / _comparisonFilterValuesCount;

        chartCol.bucket = [
          filterValuesPercent.roundToDecimal(2),
          comparisonFilterValuesPercent.roundToDecimal(2)
        ];

        if (chart.type == model.ChartType.time_series) {
          for (var datetime in chartCol.time_bucket.keys) {
            chartCol.time_bucket[datetime] =
                ((chartCol.time_bucket[datetime] * 100) /
                        _allInteractionDateBuckets[chart.timestamp.key]
                            [chart.timestamp.aggregate][datetime])
                    .roundToDecimal(2);
          }
        }
      }
    }
  }

  logger.debug('Computed chart buckets ${charts}');
}

String _generateDateTimeKey(DateTime dateTime, model.TimeAggregate aggregate) {
  switch (aggregate) {
    case model.TimeAggregate.day:
      dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0);
      break;
    case model.TimeAggregate.hour:
      dateTime = DateTime(
          dateTime.year, dateTime.month, dateTime.day, dateTime.hour, 0, 0);
      break;
    default:
      logger.error('Time series chart aggregate ${aggregate} not handled');
  }
  return STANDARD_DATE_TIME_FORMAT.format(dateTime);
}

Map<String, num> _generateEmptyDateTimeBuckets(
    DateTime start, DateTime end, model.TimeAggregate aggregate) {
  var timeBucket = Map<String, num>();
  var currentTime = DateTime(start.year, start.month, start.day, 0, 0, 0);
  var endTime = DateTime(end.year, end.month, end.day, 23, 59, 59);
  var durationToAdd;
  switch (aggregate) {
    case model.TimeAggregate.day:
      durationToAdd = Duration(days: 1);
      break;
    case model.TimeAggregate.hour:
      durationToAdd = Duration(hours: 1);
      break;
  }
  while (currentTime.isBefore(endTime)) {
    timeBucket[STANDARD_DATE_TIME_FORMAT.format(currentTime)] = 0;
    currentTime = currentTime.add(durationToAdd);
  }

  return timeBucket;
}

// Render methods
void handleNavToAnalysis({bool maintainFilters}) {
  view.clearContentTab();

  if (maintainFilters != true) {
    _selectedAnalysisTabIndex = 0;
    _activeFilters = {};
    _filterValues = {};
    _comparisonFilterValues = {};
  }

  var tabLabels =
      _config.tabs.asMap().map((i, t) => MapEntry(i, t.label)).values.toList();
  view.renderAnalysisTabs(tabLabels, _selectedAnalysisTabIndex);
  view.renderChartOptions(_dataComparisonEnabled, _dataNormalisationEnabled,
      _stackTimeSeriesEnabled);

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
        view.renderChart(
            chart.title,
            chart.narrative,
            chart_helper.generateBarChartConfig(
                chart,
                _dataComparisonEnabled,
                _dataNormalisationEnabled,
                _activeFilterValues,
                _activeComparisonFilterValues));
        break;
      case model.ChartType.time_series:
        view.renderChart(
            chart.title,
            chart.narrative,
            chart_helper.generateTimeSeriesChartConfig(
                chart, _dataNormalisationEnabled, _stackTimeSeriesEnabled));
        break;
      case model.ChartType.map:
        var mapData =
            _mapsGeoJSON[chart.geography.country][chart.geography.regionLevel];
        var mapValues = Map<String, List<num>>();
        var mapComparisonValues = Map<String, List<num>>();
        for (var field in chart.fields) {
          var regionName = field.field.value.toString();
          var normalisationValue =
              _dataNormalisationEnabled ? 100 : _filterValuesCount;
          var comparisonNormalisationValue =
              _dataNormalisationEnabled ? 100 : _comparisonFilterValuesCount;

          mapValues[regionName] = [
            field.bucket[0],
            field.bucket[0] / normalisationValue,
          ];
          mapComparisonValues[regionName] = [
            field.bucket[1],
            field.bucket[1] / comparisonNormalisationValue
          ];
        }

        view.renderGeoMap(
          chart.title,
          chart.narrative,
          mapData,
          mapValues,
          mapComparisonValues,
          _dataComparisonEnabled,
          _dataNormalisationEnabled,
          chart.colors ?? chart_helper.barChartDefaultColors,
        );
        break;
      case model.ChartType.funnel:
        var funnelChartConfig = model.FunnelChartConfig(
            isParied: true,
            data: chart.data,
            colors: chart_helper.lineChartDefaultColors);
        view.renderFunnelChart(chart.title, chart.narrative, funnelChartConfig);
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
  view.renderSettingsConfigEditor(configString);
  view.renderSettingsConfigUtility(_uniqueFieldCategoryValues);
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
      print(_dataComparisonEnabled);
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
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      _stackTimeSeriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${_stackTimeSeriesEnabled}');
      view.removeAllChartWrappers();
      _computeChartBucketsAndRender();
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
    case UIAction.copyToClipboardConfigSkeleton:
      var config = model.Config()
        ..data_paths = {'interactions': ''}
        ..filters = _uniqueFieldCategoryValues.keys
            .map((key) => model.Filter()
              ..key = key
              ..label = key)
            .toList()
        ..tabs = List<int>.generate(2, (i) => i)
            .map((i) => model.Tab()
              ..label = 'Tab $i'
              ..exclude_filters = []
              ..charts = [])
            .toList();
      var configStr = convert.jsonEncode(config.toData()).toString();
      _copyToClipboard(configStr);
      break;
    case UIAction.copyToClipboardChartConfig:
      var d = data as CopyToClipboardChartConfigData;
      var values = _uniqueFieldCategoryValues[d.key].toList();
      var valuesConfig = values
          .map((value) => model.Field()
            ..label = value
            ..field = (model.FieldOperation()
              ..key = d.key
              ..operator = model.FieldOperator.equals
              ..value = value))
          .toList();
      var chartsConfig = model.Chart()
        ..title = 'By ${d.key}'
        ..narrative = ''
        ..type = model.ChartType.bar
        ..fields = valuesConfig;
      var configStr = convert.jsonEncode(chartsConfig.toData()).toString();
      // todo: replace this with @override toString() for enums
      ['ChartType.', 'FieldOperator.'].forEach((findStr) {
        configStr = configStr.replaceAll(findStr, '');
      });
      _copyToClipboard(configStr);
      break;
    default:
  }
}

void validateConfig(model.Config config) {
  // todo: validate time_series chart
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

void _copyToClipboard(String str) {
  final textarea = html.TextAreaElement()
    ..readOnly = true
    ..value = str;
  html.document.body.append(textarea);
  textarea.select();
  html.document.execCommand('copy');
  textarea.remove();
}
