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
  'analyse': model.Link('analyse', 'Analyse', () => handleNavToAnalysis()),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

const DEFAULT_FILTER_SELECT_VALUE = '__all';
const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
var _analyseOptions = model.AnalyseOptions(0, true, false, true);
Map<int, List<model.FilterValue>> _filtersMap = {};
Map<String, Map<String, dynamic>> _mapsGeoJSON = {};

// Data
Map<String, Map<String, Map<String, dynamic>>> _dataCollections = {};
Map<String, dynamic> _configRaw;
model.Config _config;

// Views
view.DataFiltersView _dataFilterView;
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
  int index;
  bool enabled;
  ToggleActiveFilterData(this.index, this.enabled);
}

class SetFilterValueData extends Data {
  int index;
  String value;
  SetFilterValueData(this.index, this.value);
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
  // get hash from url
  var hash = html.window.location.hash;
  if (hash.isNotEmpty) {
    hash = hash.split('?')[0];
  }
  if (hash == '') {
    _currentNavLink = _navLinks.keys.first;
  } else {
    _currentNavLink = hash.replaceAll('#', '');
  }

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
  _configRaw = await fb.fetchConfig();
  try {
    _config = model.Config.fromData(_configRaw);
  } catch (e) {
    view.showAlert(UNABLE_TO_PARSE_CONFIG_ERROR_MSG);
    logger.error(e.toString());
    view.hideLoading();
  }

  // Read maps data
  await _loadGeoMapsData();

  // Initialise and compute filters
  for (var i = 0; i < _config.tabs.length; ++i) {
    _filtersMap[i] = <model.FilterValue>[];
    var currentTab = _config.tabs[i];
    currentTab.filters.forEach((filter) {
      _filtersMap[i].add(model.FilterValue(
          filter.data_collection, filter.key, filter.type, [], '', '', false));
    });
  }

  // Fill chart options and nav tab from url
  _fillDefaultOptionsFromURL();

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

  _navLinks[_currentNavLink].render();
}

void _fillDefaultOptionsFromURL() {
  var uri = Uri.dataFromString(html.window.location.href);
  var query = uri.queryParameters;
  if (query['analyseTab'] != null) {
    _analyseOptions.selectedTabIndex = int.parse(query['analyseTab']);
  }
  if (query['compare'] != null) {
    _analyseOptions.dataComparisonEnabled = query['compare'] == 'true';
  }
  if (query['normalise'] != null) {
    _analyseOptions.normaliseDataEnabled = query['normalise'] == 'true';
  }
  if (query['stackTimeSeries'] != null) {
    _analyseOptions.stackTimeseriesEnabled = query['stackTimeSeries'] == 'true';
  }

  if (query['filter.keys'] != null) {
    var keys = Uri.decodeFull(query['filter.keys']).split(',');
    var dataCollections =
        Uri.decodeFull(query['filter.collections']).split(',');
    var values = Uri.decodeFull(query['filter.values']).split(',');
    var comparisonValues =
        Uri.decodeFull(query['filter.comparisonValues']).split(',');

    for (var i = 0; i < keys.length; ++i) {
      var filters = _filtersMap[_analyseOptions.selectedTabIndex];
      filters.forEach((filter) {
        if (filter.key == keys[i] &&
            filter.dataCollection == dataCollections[i]) {
          filter.isActive = true;
          filter.value = values[i];
          filter.comparisonValue = comparisonValues[i];
        }
      });
    }
  }
}

void _pushOptionsToURL() {
  var params = <String, String>{};

  params['analyseTab'] = _analyseOptions.selectedTabIndex.toString();
  params['compare'] = _analyseOptions.dataComparisonEnabled.toString();
  params['normalise'] = _analyseOptions.normaliseDataEnabled.toString();
  params['stackTimeSeries'] = _analyseOptions.stackTimeseriesEnabled.toString();

  var filters = List<model.FilterValue>.from(
      _filtersMap[_analyseOptions.selectedTabIndex]);
  filters.removeWhere((element) => !element.isActive);
  if (filters.isNotEmpty) {
    params['filter.keys'] = filters.map((e) => e.key).toList().join(',');
    params['filter.collections'] =
        filters.map((e) => e.dataCollection).toList().join(',');
    params['filter.values'] = filters.map((e) => e.value).toList().join(',');
    params['filter.comparisonValues'] =
        filters.map((e) => e.comparisonValue).toList().join(',');
  }

  var url = Uri(queryParameters: params);
  html.window.history
      .replaceState(null, '', '#${_currentNavLink}${url.toString()}');
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

  _computeFilterOptions();

  if (_currentNavLink == _navLinks.keys.first) {
    _dataFilterView.update(_filtersMap[_analyseOptions.selectedTabIndex]);
    _computeCharts();
    _updateCharts();
  }
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
void handleNavToAnalysis() {
  view.clearContentTab();

  view.AnalyseTabsViews(_config.tabs.map((t) => t.label).toList(),
      _analyseOptions.selectedTabIndex);
  view.ChartOptionsView(
      _analyseOptions.dataComparisonEnabled,
      _analyseOptions.normaliseDataEnabled,
      _analyseOptions.stackTimeseriesEnabled);
  _dataFilterView = view.DataFiltersView();
  _dataFilterView.update(_filtersMap[_analyseOptions.selectedTabIndex]);

  _initialiseCharts();
  _computeCharts();
  _updateCharts();
}

// Filter options
void _computeFilterOptions() {
  for (var i = 0; i < _config.tabs.length; ++i) {
    var currentTab = _config.tabs[i];
    for (var j = 0; j < currentTab.filters.length; ++j) {
      var currentFilter = currentTab.filters[j];
      if (_dataCollections[currentFilter.data_collection].isEmpty) continue;
      switch (currentFilter.type) {
        case model.DataType.datetime:
          var collectionToIterate =
              _dataCollections[currentFilter.data_collection].values;
          var dates = collectionToIterate
              .map((e) => e[currentFilter.key])
              .toList()
                ..sort();
          _filtersMap[i][j].options = [dates.first, dates.last];
          if (_filtersMap[i][j].value == '') {
            _filtersMap[i][j].value =
                '${dates.first.split("T")[0]}_${dates.last.split("T")[0]}';
          }
          break;
        case model.DataType.string:
          var collectionToIterate =
              _dataCollections[currentFilter.data_collection].values;
          var options = <String>{};
          collectionToIterate.forEach((element) {
            var data = element[currentFilter.key];
            if (data is String) {
              options.add(data.toString());
            } else if (data is List) {
              data.forEach((d) {
                options.add(d.toString());
              });
            }
          });
          options.add(DEFAULT_FILTER_SELECT_VALUE);
          _filtersMap[i][j].options = options.toList();
          if (_filtersMap[i][j].value == '') {
            _filtersMap[i][j].value = DEFAULT_FILTER_SELECT_VALUE;
          }
          if (_filtersMap[i][j].comparisonValue == '') {
            _filtersMap[i][j].comparisonValue = DEFAULT_FILTER_SELECT_VALUE;
          }
          break;
        default:
      }
    }
  }
}

// Charts
void _initialiseCharts() {
  _chartsInView.forEach((chart) {
    view.removeChart(chart.id);
  });
  _chartsInView = [];
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
        var newChart = chart_model.UnimplementedChart();
        _chartsInView.add(newChart);
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
          for (var filter in _filtersMap[_analyseOptions.selectedTabIndex]) {
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
    } else if (_chartsInView[i] is chart_model.UnimplementedChart) {
      (_chartsInView[i] as chart_model.UnimplementedChart).updateChartinView();
    }
  }
}

void handleNavToSettings() {
  view.clearContentTab();
  var encoder = convert.JsonEncoder.withIndent('  ');
  var configString = encoder.convert(_configRaw);
  view.renderSettingsConfigEditor(configString);
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

      _dataFilterView.update(_filtersMap[_analyseOptions.selectedTabIndex]);

      _pushOptionsToURL();
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
      _pushOptionsToURL();
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
      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      _analyseOptions.stackTimeseriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${_analyseOptions.stackTimeseriesEnabled}');
      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      _filtersMap[_analyseOptions.selectedTabIndex][d.index].isActive =
          d.enabled;
      var filter = _filtersMap[_analyseOptions.selectedTabIndex][d.index];
      d.enabled
          ? view.enableFilterOptions(filter.dataCollection, filter.key)
          : view.disableFilterOptions(filter.dataCollection, filter.key);

      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      _filtersMap[_analyseOptions.selectedTabIndex][d.index].value = d.value;

      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      _filtersMap[_analyseOptions.selectedTabIndex][d.index].comparisonValue =
          d.value;

      _pushOptionsToURL();
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
