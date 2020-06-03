import 'package:dashboard/navbar/model.dart' as nav_model;
import 'package:dashboard/navbar/controller.dart' as nav_controller;
import 'logger.dart';
import 'dart:html' as html;
import 'package:dashboard/utils.dart' as utils;

Logger logger = Logger('app.dart');

var links = [
  nav_model.Link('/charts', 'Charts'),
  nav_model.Link('/settings', 'Settings'),
];

class App {
  nav_controller.Controller navController;
  App() {
    navController = nav_controller.Controller(links);
    _handlePathChange(null);
    utils.listenToPathChanges(_handlePathChange);
  }

  void _handlePathChange(html.Event event) {
    logger.log('updated url to ${utils.currentPathname}');
    switch (utils.currentPathname) {
      case '/charts':
        logger.log('Render charts');
        break;
      case '/settings':
        logger.log('Render settings');
        break;
      default:
        logger.log('No route present');
        break;
    }
  }
}
