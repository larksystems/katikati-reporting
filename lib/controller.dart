library controller;

import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/logger.dart';

Logger logger = Logger('controller.dart');

Map<String, model.Link> _navLinks = {
  'analyse': model.Link('analyse', 'Analyse', view.renderAnalyseTab),
  'settings': model.Link('settings', 'Settings', view.renderSettingsTab)
};

var _currentNavLink = _navLinks['analyse'].pathname;

// Actions
enum UIAction { signinWithGoogle, changeNavTab }

// Action data
class Data {}

class NavChangeData extends Data {
  String pathname;
  NavChangeData(this.pathname);
}

// Controller functions
void init() async {
  view.init();
  view.showLoginModal();
  _navLinks.forEach((_, n) {
    view.appendNavLink(n.pathname, n.label, _currentNavLink == n.pathname);
  });

  await fb.init(
      'assets/firebase-constants.json', onLoginCompleted, onLogoutCompleted);
}

void onLoginCompleted() async {
  await loadDataFromFirebase();
  view.setNavlinkSelected(_currentNavLink);
  _navLinks['analyse'].render();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
}

void loadDataFromFirebase() async {
  view.showLoading();
  logger.debug('Read all required data');
  view.hideLoading();
}

void command(UIAction action, Data data) {
  switch (action) {
    case UIAction.signinWithGoogle:
      fb.signInWithGoogle();
      break;
    case UIAction.changeNavTab:
      var d = data as NavChangeData;
      _currentNavLink = d.pathname;
      view.setNavlinkSelected(_currentNavLink);
      _navLinks[_currentNavLink].render();
      break;
    default:
  }
}
