import 'dart:html' as html;
import 'package:firebase/firebase.dart' as firebase;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/utils.dart' as utils;
import 'package:dashboard/navbar/controller.dart' as nav_controller;
import 'package:dashboard/logger.dart';

Logger logger = Logger('app.dart');

var links = [
  model.Link('/charts', 'Charts'),
  model.Link('/settings', 'Settings'),
];

html.ButtonElement get loginButton => html.querySelector('#login-button');

class App {
  nav_controller.Controller navController;

  App() {
    initFirebase();
    // TO THINK ABOUT: navController might want to take in the respective controllers as well
    navController = nav_controller.Controller(links);
    utils.listenToPathChanges(_handlePath);
  }

  void _loadData() async {
    logger.debug('Loading all data ...');
  }

  void _handlePath(_) {
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

  void initFirebase() async {
    await fb.init('firebase/constants.json');
    utils.setLoginDomains(fb.allowedEmailDomains);
    fb.firebaseAuth.onAuthStateChanged.listen(_fbAuthChanged);
    loginButton.onClick.listen((_) {
      utils.disableLoginButton();
      fb.signInWithGoogle();
    });
  }

  void _fbAuthChanged(firebase.User user) async {
    utils.enableLoginButton();
    if (user == null) {
      logger.debug('User not signed in');
      utils.showLoginModal();
      return;
    }

    if (!fb.allowedEmailDomains.any((domain) => user.email.endsWith(domain))) {
      logger.error('Email domain not allowed');
      await fb.deleteUser();
      utils.showLoginError('Email domain not allowed');
      return;
    }

    if (!user.emailVerified) {
      logger.error('Email not verified');
      await fb.deleteUser();
      utils.showLoginError('Email is not verified');
      return;
    }

    logger.debug('Loggedin as ${user.email}');
    utils.hideLoginError();
    utils.hideLoginModal();

    await _loadData();
    _handlePath(null);
  }
}
