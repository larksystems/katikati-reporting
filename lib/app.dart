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
    // TO THINK ABOUT: navController might want to take in the respective controllers as well
    navController = nav_controller.Controller(links);
    _handlePath(null);
    utils.listenToPathChanges(_handlePath);
  }

  void _handlePath(html.Event event) {
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
