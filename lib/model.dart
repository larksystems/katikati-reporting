export 'package:dashboard/model.g.dart';

import 'package:dashboard/model.g.dart';

class Config {
  String docId;
  Map<String, String> data_collections;
  List<Tab> tabs;

  static Config fromData(data, [Config modelObj]) {
    if (data == null) return null;

    var data_collections = <String, String>{};
    data['data_collections'].forEach((key, path) {
      data_collections[key] = path;
    });

    return (modelObj ?? Config())
      ..data_collections = data_collections
      ..tabs = List_fromData<Tab>(data['tabs'], Tab.fromData);
  }
}

class AnalyseOptions {
  int selectedTabIndex;
  bool dataComparisonEnabled;
  bool normaliseDataEnabled;
  bool stackTimeseriesEnabled;

  AnalyseOptions(this.selectedTabIndex, this.dataComparisonEnabled,
      this.normaliseDataEnabled, this.stackTimeseriesEnabled);

  void updateFrom(Map<String, dynamic> object) {
    selectedTabIndex = object['selectedTabIndex'] ?? selectedTabIndex;
    dataComparisonEnabled =
        object['dataComparisonEnabled'] ?? dataComparisonEnabled;
    normaliseDataEnabled =
        object['normaliseDataEnabled'] ?? normaliseDataEnabled;
    stackTimeseriesEnabled =
        object['stackTimeseriesEnabled'] ?? stackTimeseriesEnabled;
  }

  Map<String, dynamic> toObject() {
    return {
      'selectedTabIndex': selectedTabIndex,
      'dataComparisonEnabled': dataComparisonEnabled,
      'normaliseDataEnabled': normaliseDataEnabled,
      'stackTimeseriesEnabled': stackTimeseriesEnabled
    };
  }
}

class Link {
  String pathname;
  String label;
  void Function() render;

  Link(this.pathname, this.label, this.render);
}

class FilterValue {
  String dataCollection;
  String key;
  DataType type;
  List<String> options;
  String value;
  String comparisonValue;
  bool isActive;

  FilterValue(this.dataCollection, this.key, this.type, this.options,
      this.value, this.comparisonValue, this.isActive);
}

abstract class ComputedChart {
  String dataCollection;
  String title;
  String narrative;
  ChartType type;
  List<String> colors;

  ComputedChart(
      this.dataCollection, this.title, this.narrative, this.type, this.colors);
}

class ComputedBarChart extends ComputedChart {
  String dataLabel;
  List<String> labels;
  List<List<num>> buckets;
  List<List<num>> normaliseValues;
  List<String> seriesNames;

  ComputedBarChart(
      String dataCollection,
      String title,
      String narrative,
      List<String> colors,
      this.dataLabel,
      this.labels,
      this.buckets,
      this.normaliseValues,
      this.seriesNames)
      : super(dataCollection, title, narrative, ChartType.bar, colors);
}

class ComputedTimeSeriesChart extends ComputedChart {
  String dataLabel;
  String docName;
  List<String> seriesLabels;
  Map<DateTime, List<num>> buckets;

  ComputedTimeSeriesChart(
      String dataCollection,
      this.docName,
      String title,
      String narrative,
      List<String> colors,
      this.dataLabel,
      this.seriesLabels,
      this.buckets)
      : super(dataCollection, title, narrative, ChartType.time_series, colors);
}

class ComputedFunnelChart extends ComputedChart {
  bool isCoupled;
  List<String> stages;
  List<num> values;

  ComputedFunnelChart(String dataCollection, String title, String narrative,
      List<String> colors, this.stages, this.values, this.isCoupled)
      : super(dataCollection, title, narrative, ChartType.funnel, colors);
}

class ComputedMapChart extends ComputedChart {
  List<String> labels;
  List<List<num>> buckets;
  List<List<num>> normaliseValues;
  List<String> seriesNames;
  List<String> mapPath;

  ComputedMapChart(
      String dataCollection,
      String title,
      String narrative,
      List<String> colors,
      this.labels,
      this.buckets,
      this.normaliseValues,
      this.seriesNames,
      this.mapPath)
      : super(dataCollection, title, narrative, ChartType.map, colors);
}
