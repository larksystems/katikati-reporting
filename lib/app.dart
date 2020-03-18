import 'dart:html' as html;
import 'firebase.dart' as fb;

html.DivElement get summaryWrapper =>
    html.querySelector('#summary-metrics-wrapper');

class App {
  App() {
    _initFirebase();
  }

  void _initFirebase() async {
    await fb.init();
  }
}
