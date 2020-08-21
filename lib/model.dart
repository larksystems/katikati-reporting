export 'package:dashboard/model.g.dart';
import 'package:dashboard/model.g.dart';

class Config {
  String docId;
  Map<String, String> data_collections;
  Map<String, String> data_documents;
  List<Tab> tabs;

  static Config fromData(data, [Config modelObj]) {
    if (data == null) return null;

    var data_collections = <String, String>{};
    data['data_collections'].forEach((key, mapValue) {
      mapValue.forEach((k, v) {
        data_collections[key] = v.toString();
      });
    });

    var data_documents = <String, String>{};
    data['data_documents'].forEach((key, mapValue) {
      mapValue.forEach((k, v) {
        data_documents[key] = v.toString();
      });
    });

    return (modelObj ?? Config())
      ..data_collections = data_collections
      ..data_documents = data_documents
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
  DataPath dataPath;
  String key;
  DataType type;
  List<String> options;
  String value;
  String comparisonValue;
  bool isActive;

  FilterValue(this.dataPath, this.key, this.type, this.options, this.value,
      this.comparisonValue, this.isActive);
}

abstract class ComputedChart {
  DataPath dataPath;
  String title;
  String narrative;
  ChartType type;
  List<String> colors;

  ComputedChart(
      this.dataPath, this.title, this.narrative, this.type, this.colors);
}

class ComputedBarChart extends ComputedChart {
  String dataLabel;
  List<String> labels;
  List<List<num>> buckets;
  List<List<num>> normaliseValues;
  List<String> seriesNames;

  ComputedBarChart(
      DataPath dataPath,
      String title,
      String narrative,
      List<String> colors,
      this.dataLabel,
      this.labels,
      this.buckets,
      this.normaliseValues,
      this.seriesNames)
      : super(dataPath, title, narrative, ChartType.bar, colors);
}

class ComputedTimeSeriesChart extends ComputedChart {
  String dataLabel;
  String docName;
  List<String> seriesLabels;
  Map<DateTime, List<num>> buckets;

  ComputedTimeSeriesChart(
      DataPath dataPath,
      this.docName,
      String title,
      String narrative,
      List<String> colors,
      this.dataLabel,
      this.seriesLabels,
      this.buckets)
      : super(dataPath, title, narrative, ChartType.time_series, colors);
}

class ComputedFunnelChart extends ComputedChart {
  bool isCoupled;
  List<String> stages;
  List<num> values;

  ComputedFunnelChart(DataPath dataPath, String title, String narrative,
      List<String> colors, this.stages, this.values, this.isCoupled)
      : super(dataPath, title, narrative, ChartType.funnel, colors);
}

class ComputedMapChart extends ComputedChart {
  List<String> labels;
  List<List<num>> buckets;
  List<List<num>> normaliseValues;
  List<String> seriesNames;
  List<String> mapPath;

  ComputedMapChart(
      DataPath dataPath,
      String title,
      String narrative,
      List<String> colors,
      this.labels,
      this.buckets,
      this.normaliseValues,
      this.seriesNames,
      this.mapPath)
      : super(dataPath, title, narrative, ChartType.map, colors);
}
