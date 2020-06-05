import 'package:dashboard/model.dart' as model;
import 'package:dashboard/path.dart' as path;
import 'package:dashboard/navbar/controller.dart' as nav_controller;
import 'package:dashboard/login/controller.dart' as login_controller;
import 'package:dashboard/view.dart' as app_view;
import 'package:dashboard/logger.dart';

Logger logger = Logger('app.dart');

var links = [
  model.Link('/charts', 'Charts'),
  model.Link('/settings', 'Settings'),
];

class App {
  app_view.View view;
  login_controller.Controller loginController;
  nav_controller.Controller navController;

  App() {
    loginController =
        login_controller.Controller(_onSignInComplete, _onSignOutComplete);
    // TO THINK ABOUT: navController might want to take in the respective controllers as well
    navController = nav_controller.Controller(links);
    path.listenToChanges(_handlePath);
  }

  void _onSignInComplete() async {
    view.showLoadingIndicator();
    logger.debug('Loading all data ...');
    view.hideLoadingIndicator();
  }

  void _onSignOutComplete() {
    logger.debug('Clearing all data ...');
  }

  void _handlePath(_) {
    logger.debug('updated url to ${path.currentName}');
    switch (path.currentName) {
      case '/charts':
        logger.debug('Render charts');
        break;
      case '/settings':
        logger.debug('Render settings');
        break;
      default:
        logger.error('Route ${path.currentName} not handled, showing 404 page');
        break;
    }
  }
}
