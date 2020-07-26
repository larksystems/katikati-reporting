export 'package:dashboard/model.g.dart';

class Link {
  String pathname;
  String label;
  void Function() render;

  Link(this.pathname, this.label, this.render);
}

class FunnelData {
  String label;
  num value;

  FunnelData(this.label, this.value);
}

class FunnelChartConfig {
  bool isParied;
  List<String> colors;
  List<FunnelData> data;

  FunnelChartConfig({this.data, this.isParied, this.colors});
}
