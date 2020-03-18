import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;

html.DivElement get summaryWrapper =>
    html.querySelector('#summary-metrics-wrapper');

class App {
  List<model.DaySummary> _summaryMetrics;

  App() {
    _initFirebase();
  }

  void _initFirebase() async {
    await fb.init();
    _summaryMetrics = await fb.readSummaryMetrics();
  }
}
