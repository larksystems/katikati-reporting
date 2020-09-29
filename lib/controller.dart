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
import 'package:dashboard/url_handler.dart' as url_handler;

Logger logger = Logger('controller.dart');

final analysisPage = model.Link('analysis', 'Analyse', handleNavToAnalysis);
final settingsPage = model.Link('settings', 'Settings', handleNavToSettings);
final DEFAULT_PAGE = analysisPage;
final _navLinks = <String, model.Link>{
  analysisPage.pathname: analysisPage,
  settingsPage.pathname: settingsPage,
};

const DEFAULT_FILTER_SELECT_VALUE = '__all';
const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';

// UI States
int selectedTab;
final model.AnalysisOptions analysisOptions = model.AnalysisOptions();
Map<int, List<model.FilterValue>> filtersByTab = {};
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
  url_handler.page ??= DEFAULT_PAGE.pathname;

  view.init();
  view.showLoginModal();
  _navLinks.forEach((_, n) {
    view.appendNavLink(n.pathname, n.label, url_handler.page == n.pathname);
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
    filtersByTab[i] = <model.FilterValue>[];
    var currentTab = _config.tabs[i];
    currentTab.filters.forEach((filter) {
      filtersByTab[i].add(model.FilterValue(
          filter.dataCollection, filter.key, filter.type, [], '', '', false));
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

  _navLinks[url_handler.page].render();
  _pushOptionsToURL();
}

void _fillDefaultOptionsFromURL() {
  if (url_handler.analysisTab != null) {
    selectedTab = int.parse(url_handler.analysisTab);
  }
  if (url_handler.compare != null) {
    analysisOptions.dataComparisonEnabled = url_handler.compare;
  }
  if (url_handler.normalise != null) {
    analysisOptions.normaliseDataEnabled = url_handler.normalise;
  }
  if (url_handler.stack != null) {
    analysisOptions.stackTimeseriesEnabled = url_handler.stack;
  }

  if (url_handler.filterKeys != null) {
    var keys = url_handler.filterKeys;
    var dataCollections = url_handler.filterCollections;
    var values = url_handler.filterValues;
    var comparisonValues = url_handler.filterComparisonValues;

    for (var i = 0; i < keys.length; ++i) {
      var filters = filtersByTab[selectedTab];
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
  url_handler.analysisTab = selectedTab.toString();
  url_handler.compare = analysisOptions.dataComparisonEnabled;
  url_handler.normalise = analysisOptions.normaliseDataEnabled;
  url_handler.stack = analysisOptions.stackTimeseriesEnabled;

  var filters = List<model.FilterValue>.from(filtersByTab[selectedTab]);
  filters.removeWhere((element) => !element.isActive);
  if (filters.isNotEmpty) {
    url_handler.filterKeys = filters.map((e) => e.key).toList();
    url_handler.filterCollections = filters.map((e) => e.dataCollection).toList();
    url_handler.filterValues = filters.map((e) => e.value).toList();
    url_handler.filterComparisonValues = filters.map((e) => e.comparisonValue).toList();
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

  _computeFilterOptions();

  if (url_handler.page == _navLinks.keys.first) {
    _dataFilterView.update(filtersByTab[selectedTab], analysisOptions.dataComparisonEnabled);
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
      selectedTab);
  view.ChartOptionsView(
      analysisOptions.dataComparisonEnabled,
      analysisOptions.normaliseDataEnabled,
      analysisOptions.stackTimeseriesEnabled);
  _dataFilterView = view.DataFiltersView();
  _dataFilterView.update(filtersByTab[selectedTab],
      analysisOptions.dataComparisonEnabled);

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
      if (_dataCollections[currentFilter.dataCollection].isEmpty) continue;
      switch (currentFilter.type) {
        case model.DataType.datetime:
          var collectionToIterate =
              _dataCollections[currentFilter.dataCollection].values;
          var dates = collectionToIterate
              .map((e) => e[currentFilter.key])
              .toList()
                ..sort();
          filtersByTab[i][j].options = [dates.first, dates.last];
          // todo: refactor to a function
          if (filtersByTab[i][j].value == '') {
            filtersByTab[i][j].value =
                '${dates.first.split("T")[0]}_${dates.last.split("T")[0]}';
          }
          break;
        case model.DataType.string:
          var collectionToIterate =
              _dataCollections[currentFilter.dataCollection].values;
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
          filtersByTab[i][j].options = options.toList();
          if (filtersByTab[i][j].value == '') {
            filtersByTab[i][j].value = DEFAULT_FILTER_SELECT_VALUE;
          }
          if (filtersByTab[i][j].comparisonValue == '') {
            filtersByTab[i][j].comparisonValue = DEFAULT_FILTER_SELECT_VALUE;
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
  var charts = _config.tabs[selectedTab].charts;
  for (var chart in charts) {
    switch (chart.type) {
      case model.ChartType.summary:
        var newChart = chart_model.SummaryChart(chart.title,
            chart.fields.labels, chart.fields.labels.map((e) => 0).toList());
        _chartsInView.add(newChart);
        break;
      case model.ChartType.time_series:
        var newChart = chart_model.TimeSeriesLineChart(
            chart.title,
            chart.data_collection,
            chart.data_label,
            chart.fields.labels,
            chart.colors, <DateTime, List<num>>{});
        _chartsInView.add(newChart);
        break;
      case model.ChartType.bar:
        var buckets = <String, List<num>>{};
        var normaliseBuckets = <String, List<num>>{};
        var labelMap = <String, String>{};

        for (var i = 0; i < chart.fields.values.length; ++i) {
          var value = chart.fields.values[i];
          labelMap[value] = chart.fields.labels[i];
          buckets[value] = [0, 0];
          normaliseBuckets[value] = [0, 0];
        }

        var newChart = chart_model.BarChart(
            chart.title,
            chart.data_collection,
            labelMap,
            chart.data_label,
            ['All ${chart.data_label}', 'All ${chart.data_label}'],
            chart.colors,
            buckets,
            normaliseBuckets);
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
  var charts = _config.tabs[selectedTab].charts;

  for (var i = 0; i < charts.length; ++i) {
    var chart = charts[i];
    if (_dataCollections[chart.data_collection] == null) continue;
    var filteredCollection = <String, dynamic>{};
    var filteredComparisonCollection = <String, dynamic>{};
    _dataCollections[chart.data_collection].forEach((key, dataValue) {
      var toAddFiltered = true;
      var toAddFilteredComparison = true;
      for (var filter in filtersByTab[selectedTab]) {
        if (filter.type == model.DataType.datetime) {
          var date = DateTime.parse(key);
          var startDate = DateTime.parse(filter.value.split('_').first);
          var endDate = DateTime.parse(filter.value.split('_').last)
              .add(Duration(days: 1));
          if (date.isBefore(startDate) || date.isAfter(endDate)) {
            toAddFiltered = false;
          }
        } else if (filter.type == model.DataType.string) {
          var value = dataValue[filter.key];
          if (filter.value != DEFAULT_FILTER_SELECT_VALUE) {
            if (value is String && filter.value != value) {
              toAddFiltered = false;
            } else if (value is List && !value.contains(filter.value)) {
              toAddFiltered = false;
            }
          }
          if (filter.comparisonValue != DEFAULT_FILTER_SELECT_VALUE) {
            if (value is String && filter.comparisonValue != value) {
              toAddFilteredComparison = false;
            } else if (value is List &&
                !value.contains(filter.comparisonValue)) {
              toAddFilteredComparison = false;
            }
          }
        }
      }
      if (toAddFiltered) {
        filteredCollection[key] = dataValue;
      }
      if (toAddFilteredComparison) {
        filteredComparisonCollection[key] = dataValue;
      }
    });
    switch (chart.type) {
      case model.ChartType.summary:
        var computedValues = <num>[];
        for (var j = 0; j < chart.fields.values.length; ++j) {
          var values = chart.fields.values;
          var aggregateMethods = chart.fields.aggregateMethod;
          var aggregateValue = 0 as num;
          filteredCollection.forEach((_, valueObj) {
            var value = valueObj[values[i]];
            aggregateValue += value;
          });
          if (aggregateMethods[j] == 'average') {
            aggregateValue = aggregateValue / filteredCollection.keys.length;
            aggregateValue = aggregateValue.roundToDecimal(1);
          }
          computedValues.add(aggregateValue);
        }

        var chartInView = (_chartsInView[i] as chart_model.SummaryChart);
        chartInView.values = computedValues;
        break;
      case model.ChartType.time_series:
        var buckets = filteredCollection.map((_, valueObj) {
          var values =
              chart.fields.values.map((e) => valueObj[e] as num).toList();
          return MapEntry(
              DateTime.parse(valueObj[chart.timestamp.key]), values);
        });
        var chartInView = (_chartsInView[i] as chart_model.TimeSeriesLineChart);
        chartInView.buckets = buckets;

        if (analysisOptions.normaliseDataEnabled) {
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
      case model.ChartType.bar:
        var chartInView = _chartsInView[i] as chart_model.BarChart;
        chartInView.buckets.forEach((key, value) {
          chartInView.buckets[key] = [0, 0];
          chartInView.normaliseBuckets[key] = [
            filteredCollection.length,
            filteredComparisonCollection.length
          ];
        });

        filteredCollection.forEach((key, document) {
          for (var j = 0; j < chart.fields.values.length; ++j) {
            var value = document[chart.fields.key];
            if (value is String && value == chart.fields.values[j]) {
              ++chartInView.buckets[chart.fields.values[j]][0];
            } else if (value is List &&
                value.contains(chart.fields.values[j])) {
              ++chartInView.buckets[chart.fields.values[j]][0];
            }
          }
        });

        filteredComparisonCollection.forEach((key, document) {
          for (var j = 0; j < chart.fields.values.length; ++j) {
            var value = document[chart.fields.key];
            if (value is String && value == chart.fields.values[j]) {
              ++chartInView.buckets[chart.fields.values[j]][1];
            } else if (value is List &&
                value.contains(chart.fields.values[j])) {
              ++chartInView.buckets[chart.fields.values[j]][1];
            }
          }
        });

        var primaryLabels = filtersByTab[selectedTab]
            .map((e) => e.isActive ? '${e.key}: ${e.value}' : null)
            .toList();
        primaryLabels.removeWhere((e) => e == null);
        if (primaryLabels.isEmpty) {
          primaryLabels.add('All ${chart.data_label}');
        }

        var comparisonLabels = filtersByTab[selectedTab]
            .map((e) => e.isActive ? '${e.key}: ${e.comparisonValue}' : null)
            .toList();
        comparisonLabels.removeWhere((e) => e == null);
        if (comparisonLabels.isEmpty) {
          comparisonLabels.add('All ${chart.data_label}');
        }

        chartInView.seriesNames = [
          primaryLabels.join(', '),
          comparisonLabels.join(', ')
        ];
        break;
      default:
    }
  }
}

void _updateCharts() {
  var charts = _config.tabs[selectedTab].charts;

  for (var i = 0; i < charts.length; ++i) {
    if (_chartsInView[i] is chart_model.TimeSeriesLineChart) {
      (_chartsInView[i] as chart_model.TimeSeriesLineChart).updateChartinView(
          analysisOptions.normaliseDataEnabled,
          analysisOptions.stackTimeseriesEnabled);
    } else if (_chartsInView[i] is chart_model.SummaryChart) {
      (_chartsInView[i] as chart_model.SummaryChart).updateChartInView();
    } else if (_chartsInView[i] is chart_model.BarChart) {
      (_chartsInView[i] as chart_model.BarChart).updateChartInView(
          analysisOptions.normaliseDataEnabled,
          analysisOptions.dataComparisonEnabled);
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
      url_handler.page = d.pathname;
      view.setNavlinkSelected(d.pathname);
      _navLinks[d.pathname].render();
      break;
    case UIAction.changeAnalysisTab:
      var d = data as AnalysisTabChangeData;
      selectedTab = d.tabIndex;

      _dataFilterView.update(filtersByTab[selectedTab],
          analysisOptions.dataComparisonEnabled);

      _pushOptionsToURL();
      _initialiseCharts();
      _computeCharts();
      _updateCharts();
      logger
          .debug('Changed to analysis tab ${selectedTab}');
      break;
    case UIAction.toggleDataComparison:
      var d = data as ToggleOptionEnabledData;
      analysisOptions.dataComparisonEnabled = d.enabled;
      // view.removeFiltersWrapper();
      _dataFilterView.update(filtersByTab[selectedTab],
          analysisOptions.dataComparisonEnabled);
      _pushOptionsToURL();
      _updateCharts();
      logger.debug(
          'Data comparison changed to ${analysisOptions.dataComparisonEnabled}');
      break;
    case UIAction.toggleDataNormalisation:
      var d = data as ToggleOptionEnabledData;
      analysisOptions.normaliseDataEnabled = d.enabled;
      logger.debug(
          'Data normalisation changed to ${analysisOptions.normaliseDataEnabled}');
      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      analysisOptions.stackTimeseriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${analysisOptions.stackTimeseriesEnabled}');
      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      filtersByTab[selectedTab][d.index].isActive =
          d.enabled;
      var filter = filtersByTab[selectedTab][d.index];
      d.enabled
          ? view.enableFilterOptions(filter.dataCollection, filter.key)
          : view.disableFilterOptions(filter.dataCollection, filter.key);

      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      filtersByTab[selectedTab][d.index].value = d.value;

      _pushOptionsToURL();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      filtersByTab[selectedTab][d.index].comparisonValue =
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
