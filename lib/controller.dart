library controller;

import 'dart:convert' as convert;
import 'dart:html' as html;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/charts.dart' as chart_model;
import 'package:firebase/firestore.dart';
import 'package:dashboard/extensions.dart';
import 'package:dashboard/logger.dart';

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link(
      'analyse', 'Analyse', () => handleNavToAnalysis(maintainFilters: false)),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

const DEFAULT_FILTER_SELECT_VALUE = '__all';

const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';
const UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG = 'Unable to fetch interactions';
const UNABLE_TO_FETCH_MESSAGE_STATUS_ERROR_MSG =
    'Unable to fetch message status';
const UNABLE_TO_FETCH_SURVEY_STATUS_ERROR_MSG = 'Unable to fetch survey status';

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
var _analyseOptions = model.AnalyseOptions(0, true, false, true);
List<model.FilterValue> _filters = [];

Map<String, Map<String, dynamic>> _mapsGeoJSON = {};

// Data
Map<String, Map<String, Map<String, dynamic>>> _dataCollections = {};

Map<String, Map<String, Set>> _uniqueFieldValues;

Map<String, dynamic> _configRaw;
model.Config _config;
List<chart_model.Chart> _chartsInView = [];

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
  String dataPath;
  String key;
  bool enabled;
  ToggleActiveFilterData(this.dataPath, this.key, this.enabled);
}

class SetFilterValueData extends Data {
  String dataPath;
  String key;
  String value;
  SetFilterValueData(this.dataPath, this.key, this.value);
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

  // Read config, parse config
  var _configRaw = await fb.fetchConfig();
  try {
    _config = model.Config.fromData(_configRaw);
  } catch (e) {
    view.showAlert(UNABLE_TO_PARSE_CONFIG_ERROR_MSG);
    logger.error(e.toString());
    view.hideLoading();
  }

  // Read maps data
  await _loadGeoMapsData();

  handleNavToAnalysis();

  // Listen to all data, store to _dataCollections
  for (var pathname in _config.data_collections.keys) {
    var path = _config.data_collections[pathname];
    fb.listenToCollections(path, (QuerySnapshot querySnapshot) {
      var dataMap = _dataCollections[pathname] ?? {};
      querySnapshot.docChanges().forEach((docChange) {
        if (docChange.type == 'added' || docChange.type == 'modified') {
          dataMap[docChange.doc.id] = docChange.doc.data();
        }
        if (docChange.type == 'removed') {
          dataMap.remove(docChange.doc.id);
        }
      });
      _dataCollections[pathname] = dataMap;
      _reactToDataChanges();
    }, (e) {
      view.showAlert('Unable to fetch ${pathname} data');
      logger.error(e.toString());
    });
  }
}

void _reactToDataChanges() {
  // check if all the data is filled
  for (var key in _config.data_collections.keys) {
    if (_dataCollections[key] == null) {
      return;
    }
  }

  view.hideLoading();

  print('All data collections are fetched, reacting to new changes..');

  // _initialiseFilters();
  // _updateFilters();

  _computeCharts();
  _updateCharts();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
}

void _loadGeoMapsData() async {
  for (var tab in _config.tabs) {
    for (var chart in tab.charts) {
      if (chart.type == model.ChartType.map) {
        var country = chart.geography.country;
        var regionLevel = chart.geography.regionLevel.name;
        var mapPath = 'assets/maps/${country}/${regionLevel}.geojson';
        var geostr;
        try {
          geostr = await html.HttpRequest.getString(mapPath);
        } catch (e) {
          view.showAlert(
              'Failed to get geography map ${country}/${regionLevel}');
          rethrow;
        }

        var geojson = convert.jsonDecode(geostr);

        _mapsGeoJSON[country] = _mapsGeoJSON[country] ?? {};
        _mapsGeoJSON[country][regionLevel] = geojson;
      }
    }
  }
}

// Render methods
void handleNavToAnalysis({bool maintainFilters}) {
  view.clearContentTab();

  if (maintainFilters != true) {
    _analyseOptions = model.AnalyseOptions(0, true, false, true);
    _filters = [];
  }

  var uri = Uri.parse(html.window.location.href);
  var queryParams = uri.queryParameters;
  var chartOptions = convert.jsonDecode(queryParams['chartOptions'] ?? '{}');
  _analyseOptions.updateFrom(chartOptions);

  var queryTabLabel = _config.tabs[_analyseOptions.selectedTabIndex].label;

  var tabLabels =
      _config.tabs.asMap().map((i, t) => MapEntry(i, t.label)).values.toList();
  view.renderAnalysisTabs(tabLabels, queryTabLabel);
  view.renderChartOptions(
      _analyseOptions.dataComparisonEnabled,
      _analyseOptions.normaliseDataEnabled,
      _analyseOptions.stackTimeseriesEnabled);

  _initialiseFilters();
  _updateFilters();

  _initialiseCharts();
  _computeCharts();
  _updateCharts();
}

// Filters
void _clearFilters() {
  _filters = [];
  view.removeFiltersWrapper();
}

void _initialiseFilters() {
  var filtersConfig =
      _config.tabs[_analyseOptions.selectedTabIndex].filters ?? [];

  filtersConfig.forEach((filterConfig) {
    if (_dataCollections == null ||
        _dataCollections[filterConfig.data_collection] == null) return;

    var collectionToIterate =
        _dataCollections[filterConfig.data_collection].values;
    var defaultValue = '';
    var options = <String>[];
    if (filterConfig.type == model.DataType.datetime) {
      var dates = collectionToIterate.map((e) => e[filterConfig.key]).toList()
        ..sort();
      options = [dates.first, dates.last];
      defaultValue = '${dates.first.split("T")[0]}_${dates.last.split("T")[0]}';
    }
    _filters.add(model.FilterValue(
        filterConfig.data_collection,
        filterConfig.key,
        filterConfig.type,
        options,
        defaultValue,
        defaultValue,
        false));
  });
}

void _updateFilters() {
  view.removeFiltersWrapper();
  view.renderNewFilterDropdowns(
      _filters, _analyseOptions.dataComparisonEnabled);
}

// Charts
void _clearCharts() {
  _chartsInView.forEach((chart) {
    view.removeChart(chart.id);
  });
  _chartsInView = [];
}

void _initialiseCharts() {
  var charts = _config.tabs[_analyseOptions.selectedTabIndex].charts;
  for (var chart in charts) {
    switch (chart.type) {
      case model.ChartType.time_series:
        var newChart = chart_model.TimeSeriesLineChart(
            chart.title,
            chart.data_collection,
            chart.fields.labels,
            chart.colors, <DateTime, List<num>>{});
        _chartsInView.add(newChart);
        break;
      default:
    }
  }

  view.appendCharts(_chartsInView.map((e) => e.container).toList());
}

void _computeCharts() {
  var charts = _config.tabs[_analyseOptions.selectedTabIndex].charts;

  for (var i = 0; i < charts.length; ++i) {
    var chart = charts[i];
    switch (chart.type) {
      case model.ChartType.time_series:
        if (_dataCollections[chart.data_collection] == null) continue;
        var messageStats = Map.from(_dataCollections[chart.data_collection]);
        var toRemove = [];
        messageStats.forEach((dateStr, _) {
          var date = DateTime.parse(dateStr);
          for (var filter in _filters) {
            if (filter.type == model.DataType.datetime) {
              var startDate = DateTime.parse(filter.value.split('_').first);
              var endDate = DateTime.parse(filter.value.split('_').last)
                  .add(Duration(days: 1));
              if (date.isBefore(startDate) || date.isAfter(endDate)) {
                toRemove.add(dateStr);
              }
            }
          }
        });
        messageStats.removeWhere((key, value) => toRemove.contains(key));
        var buckets = messageStats.map((_, valueObj) {
          var values =
              chart.fields.values.map((e) => valueObj[e] as num).toList();
          return MapEntry(
              DateTime.parse(valueObj[chart.timestamp.key]), values);
        });
        var chartInView = (_chartsInView[i] as chart_model.TimeSeriesLineChart);
        chartInView.buckets = buckets;

        if (_analyseOptions.normaliseDataEnabled) {
          for (var date in chartInView.buckets.keys) {
            var bucket = chartInView.buckets[date];
            var normaliseValue =
                bucket.reduce((value, element) => value + element);
            if (normaliseValue == 0) {
              normaliseValue = 1;
            }
            chartInView.buckets[date] = chartInView.buckets[date].map((value) {
              return (value / normaliseValue * 100).roundToDecimal(2);
            }).toList();
          }
        }
        break;
      default:
    }
  }
}

void _updateCharts() {
  var charts = _config.tabs[_analyseOptions.selectedTabIndex].charts;

  for (var i = 0; i < charts.length; ++i) {
    if (_chartsInView[i] is chart_model.TimeSeriesLineChart) {
      (_chartsInView[i] as chart_model.TimeSeriesLineChart).updateChartinView(
          _analyseOptions.normaliseDataEnabled,
          _analyseOptions.stackTimeseriesEnabled);
    }
  }
}

void handleNavToSettings() {
  view.clearContentTab();
  var encoder = convert.JsonEncoder.withIndent('  ');
  var configString = encoder.convert(_configRaw);
  view.renderSettingsConfigEditor(configString);
}

void _replaceURLHashWithParams() {
  var params = <String, dynamic>{};
  params['chartOptions'] = convert.jsonEncode(_analyseOptions.toObject());
  _filters.forEach((filterVal) {
    if (filterVal.isActive) {
      params['filters'] = params['filters'] ?? [];
      params['filters'].add(convert.jsonEncode({
        'key': filterVal.key,
        'dataPath': filterVal.dataCollection,
        'value': filterVal.value,
        'comparisonValue': filterVal.comparisonValue
      }));
    }
  });

  var url = Uri(queryParameters: params);
  html.window.history.replaceState(null, '', url.toString());
}

// User actions
void command(UIAction action, Data data) async {
  switch (action) {
    case UIAction.signinWithGoogle:
      await fb.signInWithGoogle();
      break;
    case UIAction.changeNavTab:
      var d = data as NavChangeData;
      _currentNavLink = d.pathname;
      view.setNavlinkSelected(_currentNavLink);
      _navLinks[_currentNavLink].render();
      break;
    case UIAction.changeAnalysisTab:
      var d = data as AnalysisTabChangeData;
      _analyseOptions.selectedTabIndex = d.tabIndex;

      _clearFilters();
      _initialiseFilters();
      _updateFilters();

      _initialiseCharts();
      _replaceURLHashWithParams();
      _clearCharts();
      _initialiseCharts();
      _computeCharts();
      _updateCharts();
      logger
          .debug('Changed to analysis tab ${_analyseOptions.selectedTabIndex}');
      break;
    case UIAction.toggleDataComparison:
      var d = data as ToggleOptionEnabledData;
      _analyseOptions.dataComparisonEnabled = d.enabled;
      view.removeFiltersWrapper();
      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      logger.debug(
          'Data comparison changed to ${_analyseOptions.dataComparisonEnabled}');
      break;
    case UIAction.toggleDataNormalisation:
      var d = data as ToggleOptionEnabledData;
      _analyseOptions.normaliseDataEnabled = d.enabled;
      logger.debug(
          'Data normalisation changed to ${_analyseOptions.normaliseDataEnabled}');
      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      _analyseOptions.stackTimeseriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${_analyseOptions.stackTimeseriesEnabled}');
      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      for (var filter in _filters) {
        if (filter.dataCollection == d.dataPath && filter.key == d.key) {
          filter.isActive = !filter.isActive;
        }
      }
      d.enabled
          ? view.enableFilterOptions(d.dataPath, d.key)
          : view.disableFilterOptions(d.dataPath, d.key);

      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataCollection == d.dataPath && filter.key == d.key) {
          filter.value = d.value;
        }
      }

      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataCollection == d.dataPath && filter.key == d.key) {
          filter.comparisonValue = d.value;
        }
      }

      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
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
        view.hideLoading();
        return;
      }

      try {
        await fb.updateConfig(configJSON);
      } catch (e) {
        view.showAlert(e.toString());
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
  if (config.tabs == null) {
    throw StateError('tabs cannot be empty');
  }

  for (var tab in config.tabs) {
    for (var chart in tab.charts) {
      if (chart.data_collection == null) {
        throw StateError('Chart data_collection cannot be empty');
      }
      var chartTypes = model.ChartType.values;
      if (!chartTypes.contains(chart.type)) {
        throw StateError('Chart type is not valid');
      }

      if (chart.type == model.ChartType.map) {
        if (chart.geography == null ||
            chart.geography.country == null ||
            chart.geography.regionLevel == null) {
          throw StateError('Geography map not specified or invalid');
        }
      }

      // todo: add more chart models validation
    }
  }
}
