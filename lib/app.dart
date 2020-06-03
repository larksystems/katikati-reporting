import 'package:dashboard/model.dart' as model;
import 'package:dashboard/navbar/controller.dart' as nav_controller;
import 'logger.dart';
import 'dart:html' as html;
import 'package:dashboard/utils.dart' as utils;

Logger logger = Logger('app.dart');

var links = [
  model.Link('/charts', 'Charts'),
  model.Link('/settings', 'Settings'),
];

class App {
  nav_controller.Controller navController;
  App() {
    navController = nav_controller.Controller(links);
    _handlePathChange(null);
    utils.listenToPathChanges(_handlePathChange);
  }

  void _handlePathChange(html.Event event) {
    logger.debug('updated url to ${utils.currentPathname}');
    switch (utils.currentPathname) {
      case '/charts':
        logger.debug('Render charts');
        break;
      case '/settings':
        logger.debug('Render settings');
        break;
      default:
        logger.error(
            'Route ${utils.currentPathname} not handled, showing 404 page');
        break;
    }
  }
}
