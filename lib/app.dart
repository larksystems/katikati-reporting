import 'dart:html' as html;
import 'logger.dart';

Logger logger = Logger('app.dart');

class App {
  App() {
    var body = html.document.getElementsByTagName('body');
    body.first.append(html.ParagraphElement()..innerText = 'Hello world');
  }
}
