export 'package:dashboard/model.g.dart';
import 'package:chartjs/chartjs.dart' as chartjs;

class Link {
  String pathname;
  String label;
  void Function() render;

  Link(this.pathname, this.label, this.render);
}

class TickOptions implements chartjs.TickOptions {
  num minValue;

  @override
  set min(dynamic v) {
    minValue = v as num;
  }

  @override
  num get min => minValue;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
