import 'controller.dart';
import 'view.dart';
import 'logger.dart';

Logger logger = Logger('app.dart');

class App {
  Controller controller;
  View view;

  App() {
    view = View();
    controller = Controller('show-individuals', view);
    view.controller = controller;
  }
}
