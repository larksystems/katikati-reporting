library controller;

import 'dart:convert' as convert;
import 'dart:html' as html;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/chart_helpers.dart' as chart_helper;
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
// Map<String, Map<String, dynamic>> _allInteractions;
// Map<String, Map<String, Map<String, dynamic>>> _messageStats;
// Map<String, Map<String, dynamic>> _surveyStatus;

Map<model.DataPath, Map<String, Set>> _uniqueFieldValues;

Map<String, dynamic> _configRaw;
model.Config _config;
List<chart_model.Chart> _chartsInView = [];

List<model.ComputedChart> _computedCharts;

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

  var _configRaw = await fb.fetchConfig();
  try {
    _config = model.Config.fromData(_configRaw);
  } catch (e) {
    view.showAlert(UNABLE_TO_PARSE_CONFIG_ERROR_MSG);
    logger.error(e.toString());
    view.hideLoading();
  }

  handleNavToAnalysis();

  await loadGeoMapsData();

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
  for (var value in _dataCollections.values) {
    print(value);
  }
  _computeCharts();
  _updateCharts();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
}

void loadGeoMapsData() async {
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

// Compute data methods
Map<model.DataPath, Map<String, Set>> computeUniqueFieldValues(
    List<model.Filter> filters) {
  var uniqueFieldValues = <model.DataPath, Map<String, Set>>{};
  filters.forEach((filter) {
    var dataPath = filter.data_path;
    uniqueFieldValues[dataPath] = uniqueFieldValues[dataPath] ?? {};
    uniqueFieldValues[dataPath][filter.key] = <dynamic>{};
  });

  uniqueFieldValues.forEach((dataPath, keysObj) {
    switch (dataPath) {
      case model.DataPath.interactions:
        // _allInteractions.forEach((_, interaction) {
        //   keysObj.keys.forEach((key) {
        //     var interactionValue = interaction[key];
        //     if (interactionValue is List) {
        //       interactionValue.forEach((interactionVal) {
        //         uniqueFieldValues[dataPath][key].add(interactionVal);
        //       });
        //     } else {
        //       uniqueFieldValues[dataPath][key].add(interactionValue);
        //     }
        //   });
        // });
        break;
      case model.DataPath.message_stats:
        logger.debug('message_stats uniqueFieldValues need not be computed');
        break;
      default:
        throw UnimplementedError(
            'computeUniqueFieldValues ${dataPath} not handled');
    }
  });

  return uniqueFieldValues;
}

bool _interactionMatchesFilterValues(Map<String, dynamic> interaction,
    List<model.FilterValue> filterValues, bool comparison) {
  for (var filter in filterValues) {
    if (!filter.isActive) continue;
    if (filter.value == DEFAULT_FILTER_SELECT_VALUE) continue;
    if (comparison && filter.comparisonValue == DEFAULT_FILTER_SELECT_VALUE) {
      continue;
    }

    var interactionMatch;
    var interactionValue = interaction[filter.key];

    var value = comparison ? filter.comparisonValue : filter.value;

    if (interactionValue is List) {
      interactionMatch = interactionValue.contains(value);
    } else if (interactionValue is DateTime) {
      var startDate = DateTime.parse(value.split('_').first);
      var endDate =
          DateTime.parse(value.split('_').last).add(Duration(days: 1));
      interactionMatch = interactionValue.isAfter(startDate) &&
          interactionValue.isBefore(endDate);
    } else if (interactionValue is String) {
      interactionMatch = interactionValue == value;
    }
    if (!interactionMatch) {
      return false;
    }
  }
  return true;
}

bool _interactionMatchesOperation(
    Map<String, dynamic> interaction, String key, String value) {
  if (value == DEFAULT_FILTER_SELECT_VALUE) return true;
  if (interaction[key] is List && interaction[key].contains(value)) return true;

  if (interaction[key] == value) return true;

  return false;
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

  _computeFilterDropdownsAndRender(
      _config.tabs[_analyseOptions.selectedTabIndex].filters);

  _initialiseCharts();
  _computeCharts();
  _updateCharts();
}

void _computeFilterDropdownsAndRender(List<model.Filter> filters) {
  filters = filters ?? [];

  _filters = [];
  filters.forEach((f) {
    var filterOptions = <String>[];
    var defaultValue = DEFAULT_FILTER_SELECT_VALUE;
    if (f.type == model.DataType.string) {
      filterOptions = _uniqueFieldValues[f.data_path][f.key]
          .map((e) => e.toString())
          .toList()
            ..add(DEFAULT_FILTER_SELECT_VALUE);
    } else if (f.type == model.DataType.datetime) {
      filterOptions = [];
      switch (f.data_path) {
        case model.DataPath.message_stats:
          if (_dataCollections.values.isEmpty) {
            return;
          }
          // todo: check across all _messageStats, not just the first
          var dates = _dataCollections.values.first.keys.toList()..sort();
          filterOptions = [dates.first, dates.last];
          var splitCharacter = 'T';
          if (!dates.first.toString().contains(splitCharacter)) {
            splitCharacter = ' ';
          }
          // the default chosen value is the whole date range to start with
          defaultValue = dates.first.toString().split(splitCharacter).first +
              '_' +
              dates.last.toString().split(splitCharacter).first;
          break;
        default:
      }
    }

    _filters.add(model.FilterValue(f.data_path, f.key, f.type, filterOptions,
        defaultValue, defaultValue, false));
  });

  // Fill filter params from url to filterVals
  var uri = Uri.parse(html.window.location.href);
  var queryParams = uri.queryParametersAll;
  var urlFilters = queryParams['filters'] ?? [];
  urlFilters.forEach((filter) {
    var filterObj = convert.jsonDecode(filter);
    _filters.forEach((filterVal) {
      if (filterVal.key == filterObj['key'] &&
          filterVal.dataPath.name == filterObj['dataPath']) {
        filterVal.value = filterObj['value'];
        filterVal.comparisonValue =
            filterObj['comparisonValue'] ?? DEFAULT_FILTER_SELECT_VALUE;
        filterVal.isActive = true;
      }
    });
  });

  view.renderNewFilterDropdowns(
      _filters, _analyseOptions.dataComparisonEnabled);
}

void _initialiseCharts() {
  _chartsInView = [];
  var charts = _config.tabs[_analyseOptions.selectedTabIndex].charts;
  for (var chart in charts) {
    switch (chart.type) {
      case model.ChartType.time_series:
        var newChart = chart_model.TimeSeriesLineChart(
            chart.title,
            chart.data_path,
            chart.doc_name,
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
        if (_dataCollections[chart.doc_name] == null) continue;
        var messageStats = Map.from(_dataCollections[chart.doc_name]);
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
      (_chartsInView[i] as chart_model.TimeSeriesLineChart).updateChart(
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
        'dataPath': filterVal.dataPath.name,
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
      _filters = [];
      view.removeFiltersWrapper();
      view.removeAllChartWrappers();
      _computeFilterDropdownsAndRender(
          _config.tabs[_analyseOptions.selectedTabIndex].filters);
      _replaceURLHashWithParams();
      // _computeChartDataAndRender();
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
      view.removeAllChartWrappers();
      _computeFilterDropdownsAndRender(
          _config.tabs[_analyseOptions.selectedTabIndex].filters);
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
      view.removeAllChartWrappers();
      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      _analyseOptions.stackTimeseriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${_analyseOptions.stackTimeseriesEnabled}');
      view.removeAllChartWrappers();
      _replaceURLHashWithParams();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.toggleActiveFilter:
      var d = data as ToggleActiveFilterData;
      for (var filter in _filters) {
        if (filter.dataPath.name == d.dataPath && filter.key == d.key) {
          filter.isActive = !filter.isActive;
        }
      }
      d.enabled
          ? view.enableFilterOptions(d.dataPath, d.key)
          : view.disableFilterOptions(d.dataPath, d.key);

      _replaceURLHashWithParams();
      // view.removeAllChartWrappers();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataPath.name == d.dataPath && filter.key == d.key) {
          filter.value = d.value;
        }
      }

      _replaceURLHashWithParams();
      // view.removeAllChartWrappers();
      _computeCharts();
      _updateCharts();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataPath.name == d.dataPath && filter.key == d.key) {
          filter.comparisonValue = d.value;
        }
      }

      _replaceURLHashWithParams();
      // view.removeAllChartWrappers();
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
  if (config.data_paths == null) {
    throw StateError('data_paths cannot be empty');
  }

  if (config.tabs == null) {
    throw StateError('tabs cannot be empty');
  }

  for (var tab in config.tabs) {
    for (var chart in tab.charts) {
      if (chart.data_path == null) {
        throw StateError('Chart data_path cannot be empty');
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
