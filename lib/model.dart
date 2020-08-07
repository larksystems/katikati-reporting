export 'package:dashboard/model.g.dart';

import 'package:dashboard/controller.dart';
import 'package:dashboard/model.g.dart';

class Link {
  String pathname;
  String label;
  void Function() render;

  Link(this.pathname, this.label, this.render);
}

class ComputedChart {
  DataPath dataPath;
  String title;
  String narrative;
  ChartType type;
  List<String> colors;

  ComputedChart(
      this.dataPath, this.title, this.narrative, this.type, this.colors);
}

class ComputedBarChart extends ComputedChart {
  List<String> labels;
  List<List<num>> buckets;
  List<List<num>> normaliseValues;
  List<String> seriesNames;

  ComputedBarChart(DataPath dataPath, String title, String narrative,
      List<String> colors, this.labels, this.buckets, this.seriesNames)
      : super(dataPath, title, narrative, ChartType.bar, colors);
}

class ComputedTimeSeriesChart extends ComputedChart {
  List<String> seriesLabels;
  Map<DateTime, List<num>> buckets;

  ComputedTimeSeriesChart(DataPath dataPath, String title, String narrative,
      List<String> colors, this.seriesLabels, this.buckets)
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
