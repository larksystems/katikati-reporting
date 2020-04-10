import 'controller.dart';
import 'view.dart';
import 'logger.dart';

Logger logger = Logger('app.dart');

class App {
  Controller controller;
  View view;

  App() {
    view = View();
    controller = Controller('show-interactions', view);
    view.controller = controller;
  }
}
