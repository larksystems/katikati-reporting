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

  ComputedBarChart(DataPath dataPath, String title, String narrative,
      List<String> colors, this.labels, this.buckets)
      : super(dataPath, title, narrative, ChartType.bar, colors);
}

class ComputedTimeSeriesChart extends ComputedChart {
  List<String> seriesLabels;
  Map<DateTime, List<num>> buckets;

  ComputedTimeSeriesChart(DataPath dataPath, String title, String narrative,
      List<String> colors, this.seriesLabels, this.buckets)
      : super(dataPath, title, narrative, ChartType.line, colors);
}
