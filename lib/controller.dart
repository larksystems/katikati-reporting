library controller;

import 'dart:convert' as convert;
import 'dart:html' as html;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/chart_helpers.dart' as chart_helper;
import 'package:dashboard/extensions.dart';
import 'package:dashboard/logger.dart';
import 'package:intl/intl.dart' as intl;

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link('analyse', 'Analyse', handleNavToAnalysis),
  'settings': model.Link('settings', 'Settings', handleNavToSettings)
};

var STANDARD_DATE_TIME_FORMAT = intl.DateFormat('yyyy-MM-dd HH:mm:ss');

const DEFAULT_FILTER_SELECT_VALUE = '__all';

const UNABLE_TO_PARSE_CONFIG_ERROR_MSG =
    'Unable to parse "Config" to the required format';
const UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG = 'Unable to fetch interactions';
const UNABLE_TO_FETCH_MESSAGE_STATUS_ERROR_MSG =
    'Unable to fetch message status';
const UNABLE_TO_FETCH_SURVEY_STATUS_ERROR_MSG = 'Unable to fetch survey status';

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
int _selectedAnalysisTabIndex;
bool _dataComparisonEnabled = true;
bool _dataNormalisationEnabled = false;
bool _stackTimeSeriesEnabled = true;
List<model.FilterValue> _filters = [];

Map<String, Map<String, dynamic>> _mapsGeoJSON = {};

// Data
Map<String, Map<String, dynamic>> _allInteractions;
Map<String, Map<String, dynamic>> _messageStats;
Map<String, Map<String, dynamic>> _surveyStatus;

Map<model.DataPath, Map<String, Set>> _uniqueFieldValues;

Map<String, dynamic> _configRaw;
model.Config _config;

List<model.ComputedChart> computedCharts;

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

  await loadFirebaseData();
  if (_config.data_paths == null || _config.tabs == null) {
    view.hideLoading();
    return;
  }

  await loadGeoMapsData();

  _uniqueFieldValues = computeUniqueFieldValues(
      _config.tabs.map((t) => t.filters ?? []).expand((e) => e).toList());
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

  if (_config.data_paths == null) {
    return;
  }

  var interactionsPath = _config.data_paths['interactions'];
  if (interactionsPath != null) {
    try {
      _allInteractions = await fb.fetchInteractions(interactionsPath);
    } catch (e) {
      view.showAlert(UNABLE_TO_FETCH_INTERACTIONS_ERROR_MSG);
      logger.error(e);
      rethrow;
    }
  }

  var messageStatusPath = _config.data_paths['message_stats'];
  if (messageStatusPath != null) {
    try {
      _messageStats = await fb.fetchMessageStats(messageStatusPath);
    } catch (e) {
      view.showAlert(UNABLE_TO_FETCH_MESSAGE_STATUS_ERROR_MSG);
      logger.error(e);
      rethrow;
    }
  }

  var surveyStatusPath = _config.data_paths['survey_status'];
  if (surveyStatusPath != null) {
    try {
      _surveyStatus = await fb.fetchSurveyStats(surveyStatusPath);
    } catch (e) {
      view.showAlert(UNABLE_TO_FETCH_SURVEY_STATUS_ERROR_MSG);
      logger.error(e);
      rethrow;
    }
  }
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
  var uniqueFieldValues = Map<model.DataPath, Map<String, Set>>();
  filters.forEach((filter) {
    var dataPath = filter.data_path;
    uniqueFieldValues[dataPath] = uniqueFieldValues[dataPath] ?? {};
    uniqueFieldValues[dataPath][filter.key] = Set();
  });

  uniqueFieldValues.forEach((dataPath, keysObj) {
    switch (dataPath) {
      case model.DataPath.interactions:
        _allInteractions.forEach((_, interaction) {
          keysObj.keys.forEach((key) {
            var interactionValue = interaction[key];
            if (interactionValue is List) {
              interactionValue.forEach((interactionVal) {
                uniqueFieldValues[dataPath][key].add(interactionVal);
              });
            } else {
              uniqueFieldValues[dataPath][key].add(interactionValue);
            }
          });
        });
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
void handleNavToAnalysis() {
  view.clearContentTab();
  _selectedAnalysisTabIndex = 0;
  _filters = [];

  var uri = Uri.parse(html.window.location.href);
  var queryParams = uri.queryParameters;
  var queryTabLabel = queryParams['tab'] ?? _config.tabs.first.label;
  queryTabLabel = Uri.decodeComponent(queryTabLabel);
  _selectedAnalysisTabIndex =
      _config.tabs.indexWhere((tab) => tab.label == queryTabLabel);
  _selectedAnalysisTabIndex =
      _selectedAnalysisTabIndex == -1 ? 0 : _selectedAnalysisTabIndex;

  var tabLabels =
      _config.tabs.asMap().map((i, t) => MapEntry(i, t.label)).values.toList();
  view.renderAnalysisTabs(tabLabels, queryTabLabel);
  view.renderChartOptions(_dataComparisonEnabled, _dataNormalisationEnabled,
      _stackTimeSeriesEnabled);

  _computeFilterDropdownsAndRender(
      _config.tabs[_selectedAnalysisTabIndex].filters);
  _computeChartDataAndRender();
}

void _computeFilterDropdownsAndRender(List<model.Filter> filters) {
  filters = filters ?? [];

  _filters = [];
  filters.forEach((f) {
    var filterOptions = List<String>();
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
          var dates = _messageStats.keys.toList()..sort();
          filterOptions = [dates.first, dates.last];
          defaultValue = dates.first.toString().split('T').first +
              '_' +
              dates.last.toString().split('T').first;
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

  view.renderNewFilterDropdowns(_filters, _dataComparisonEnabled);
}

void _computeChartDataAndRender() {
  var charts = _config.tabs[_selectedAnalysisTabIndex].charts;
  computedCharts = [];

  // Initial data fields
  for (var chart in charts) {
    switch (chart.type) {
      case model.ChartType.bar:
        var computedChart = model.ComputedBarChart(
            chart.data_path,
            chart.title,
            chart.narrative,
            chart.colors,
            chart.data_label,
            chart.fields.labels,
            chart.fields.values.map((_) => [0, 0]).toList(),
            ['a', 'b']);
        computedCharts.add(computedChart);
        break;
      case model.ChartType.map:
        var computedChart = model.ComputedMapChart(
            chart.data_path,
            chart.title,
            chart.narrative,
            chart.colors ?? chart_helper.chartDefaultColors,
            chart.fields.values,
            chart.fields.values.map((_) => [0, 0]).toList(),
            ['a', 'b'],
            [chart.geography.country, chart.geography.regionLevel.name]);
        computedCharts.add(computedChart);
        break;
      case model.ChartType.time_series:
        var buckets = Map<DateTime, List<num>>();
        var computedChart = model.ComputedTimeSeriesChart(
            chart.data_path,
            chart.title,
            chart.narrative,
            chart.colors,
            chart.data_label,
            chart.fields.labels,
            buckets);
        computedCharts.add(computedChart);
        break;
      case model.ChartType.funnel:
        var computedChart = model.ComputedFunnelChart(
            chart.data_path,
            chart.title,
            chart.narrative,
            chart.colors,
            [],
            [],
            chart.is_paired);
        computedCharts.add(computedChart);
        break;
      default:
        computedCharts.add(null);
        logger.error(
            '_computeChartDataAndRender Chart type ${chart.type} not computed');
    }
  }

  // compute data
  for (var i = 0; i < charts.length; ++i) {
    var chart = charts[i];
    var computedChart = computedCharts[i];
    // funnel chart
    if (computedChart is model.ComputedFunnelChart) {
      switch (chart.data_path) {
        case model.DataPath.survey_status:
          var data = _surveyStatus[chart.doc_name][chart.fields.key] as List;
          data.forEach((e) {
            computedChart.stages.add(e[chart.fields.labels.first]);
            computedChart.values.add(e[chart.fields.values.first]);
          });
          break;
        default:
          logger
              .error('computed funnel chart doesnt support ${chart.data_path}');
      }
    }
    // time series chart
    else if (computedChart is model.ComputedTimeSeriesChart) {
      switch (chart.data_path) {
        case model.DataPath.message_stats:
          var messageStats = Map.from(_messageStats);
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
          computedChart.buckets = buckets;
          break;
        default:
          logger.error(
              'computed time series chart doesnt support ${chart.data_path}');
      }
    }
    // bar chart
    else if (computedChart is model.ComputedBarChart) {
      switch (chart.data_path) {
        case model.DataPath.interactions:
          _allInteractions.forEach((_, interaction) {
            var addToPrimaryBucket =
                _interactionMatchesFilterValues(interaction, _filters, false);
            var addToComparisonBucket =
                _interactionMatchesFilterValues(interaction, _filters, true);

            for (var i = 0; i < chart.fields.values.length; ++i) {
              if (!_interactionMatchesOperation(
                  interaction, chart.fields.key, chart.fields.values[i])) {
                continue;
              }
              if (addToPrimaryBucket) {
                ++computedChart.buckets[i][0];
              }
              if (addToComparisonBucket) {
                ++computedChart.buckets[i][1];
              }
            }
          });
          break;
        default:
      }
    }
    // map chart
    else if (computedChart is model.ComputedMapChart) {
      switch (chart.data_path) {
        case model.DataPath.interactions:
          _allInteractions.forEach((_, interaction) {
            var addToPrimaryBucket =
                _interactionMatchesFilterValues(interaction, _filters, false);
            var addToComparisonBucket =
                _interactionMatchesFilterValues(interaction, _filters, true);

            for (var i = 0; i < chart.fields.values.length; ++i) {
              if (!_interactionMatchesOperation(
                  interaction, chart.fields.key, chart.fields.values[i])) {
                continue;
              }
              if (addToPrimaryBucket) {
                ++computedChart.buckets[i][0];
              }
              if (addToComparisonBucket) {
                ++computedChart.buckets[i][1];
              }
            }
          });
          break;
        default:
      }
    } else {
      logger.error('computed chart not supported');
    }
  }

  // Render charts
  for (var computedChart in computedCharts) {
    if (computedChart is model.ComputedBarChart) {
      var seriesLabels = [];
      var seriesComparisonLabels = [];
      _filters.forEach((filter) {
        if (filter.isActive) {
          seriesLabels.add('${filter.key}: ${filter.value}');
          seriesComparisonLabels
              .add('${filter.key}: ${filter.comparisonValue}');
        }
      });
      var seriesLabelString =
          seriesLabels.isEmpty ? 'All' : seriesLabels.join(', ');
      var seriesComparisonLabelString = seriesComparisonLabels.isEmpty
          ? 'All'
          : seriesComparisonLabels.join(', ');

      var chartConfig = chart_helper.generateBarChartConfig(
          computedChart,
          _dataComparisonEnabled,
          _dataNormalisationEnabled,
          seriesLabelString,
          seriesComparisonLabelString);
      view.renderChart(
          computedChart.title, computedChart.narrative, chartConfig);
    } else if (computedChart is model.ComputedTimeSeriesChart) {
      var chartConfig = chart_helper.generateTimeSeriesChartConfig(
          computedChart, _dataNormalisationEnabled, _stackTimeSeriesEnabled);
      view.renderChart(
          computedChart.title, computedChart.narrative, chartConfig);
    } else if (computedChart is model.ComputedFunnelChart) {
      view.renderFunnelChart(
          computedChart.title,
          computedChart.narrative,
          computedChart.colors ?? chart_helper.chartDefaultColors,
          computedChart.stages,
          computedChart.values,
          computedChart.isCoupled);
    } else if (computedChart is model.ComputedMapChart) {
      var mapFilterValues = Map<String, List<num>>();
      var mapComparisonFilterValues = Map<String, List<num>>();

      // todo: fix the normalisation (1)
      for (var i = 0; i < computedChart.labels.length; ++i) {
        mapFilterValues[computedChart.labels[i]] = [
          computedChart.buckets[i][0],
          1
        ];
        mapComparisonFilterValues[computedChart.labels[i]] = [
          computedChart.buckets[i][1],
          1
        ];
      }

      view.renderGeoMap(
          computedChart.title,
          computedChart.narrative,
          _mapsGeoJSON[computedChart.mapPath[0]][computedChart.mapPath[1]],
          mapFilterValues,
          mapComparisonFilterValues,
          _dataComparisonEnabled,
          _dataNormalisationEnabled,
          computedChart.colors);
    } else {
      logger.error('No chart type to render');
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
  var params = Map<String, dynamic>();
  params['tab'] =
      Uri.encodeComponent(_config.tabs[_selectedAnalysisTabIndex].label);

  _filters.forEach((filterVal) {
    if (filterVal.isActive) {
      params['filters'] = params['filters'] ?? List();
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
      _selectedAnalysisTabIndex = d.tabIndex;
      _filters = [];
      view.removeFiltersWrapper();
      view.removeAllChartWrappers();
      _computeFilterDropdownsAndRender(
          _config.tabs[_selectedAnalysisTabIndex].filters);
      _replaceURLHashWithParams();
      _computeChartDataAndRender();
      logger.debug('Changed to analysis tab ${_selectedAnalysisTabIndex}');
      break;
    case UIAction.toggleDataComparison:
      var d = data as ToggleOptionEnabledData;
      _dataComparisonEnabled = d.enabled;
      view.removeFiltersWrapper();
      view.removeAllChartWrappers();
      _computeFilterDropdownsAndRender(
          _config.tabs[_selectedAnalysisTabIndex].filters);
      _computeChartDataAndRender();
      logger.debug('Data comparison changed to ${_dataComparisonEnabled}');
      break;
    case UIAction.toggleDataNormalisation:
      var d = data as ToggleOptionEnabledData;
      _dataNormalisationEnabled = d.enabled;
      logger
          .debug('Data normalisation changed to ${_dataNormalisationEnabled}');
      view.removeAllChartWrappers();
      _computeChartDataAndRender();
      break;
    case UIAction.toggleStackTimeseries:
      var d = data as ToggleOptionEnabledData;
      _stackTimeSeriesEnabled = d.enabled;
      logger.debug(
          'Stack time series chart changed to ${_stackTimeSeriesEnabled}');
      view.removeAllChartWrappers();
      _computeChartDataAndRender();
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
      view.removeAllChartWrappers();
      _computeChartDataAndRender();
      break;
    case UIAction.setFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataPath.name == d.dataPath && filter.key == d.key) {
          filter.value = d.value;
        }
      }

      _replaceURLHashWithParams();
      view.removeAllChartWrappers();
      _computeChartDataAndRender();
      break;
    case UIAction.setComparisonFilterValue:
      var d = data as SetFilterValueData;
      for (var filter in _filters) {
        if (filter.dataPath.name == d.dataPath && filter.key == d.key) {
          filter.comparisonValue = d.value;
        }
      }

      _replaceURLHashWithParams();
      view.removeAllChartWrappers();
      _computeChartDataAndRender();
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
  // todo: validate time_series chart
  // Data paths
  // if (config.data_paths == null) {
  //   throw StateError('data_paths cannot be empty');
  // }

  // if (config.data_paths['interactions'] == null) {
  //   throw StateError('data_paths > interactions cannot be empty');
  // }

  // // Filters
  // if (config.filters == null) {
  //   throw StateError('filters need to be an array');
  // }

  // for (var filter in config.filters) {
  //   if (filter.key == null) {
  //     throw StateError('filters {key} cannot be empty');
  //   }
  // }

  // // Tabs
  // if (config.tabs == null) {
  //   throw StateError('tabs cannot be empty');
  // }

  // for (var tab in config.tabs) {
  //   for (var chart in tab.charts) {
  //     for (var field in chart.fields) {
  //       if (field.field.key == null) {
  //         throw StateError('Chart field cannot be empty');
  //       }
  //       if (field.field.value == null) {
  //         throw StateError('Chart field value cannot be empty');
  //       }
  //       // no need to check for operator, as it is caught by enums
  //     }

  //     // geography map
  //     if (chart.type == model.ChartType.map) {
  //       if (chart.geography == null ||
  //           chart.geography.country == null ||
  //           chart.geography.regionLevel == null) {
  //         throw StateError('Geography map not specified');
  //       }
  //     }
  //   }
  // }
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
