library controller;

import 'package:dashboard/model.dart' as model;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/logger.dart';

Logger logger = Logger('controller.dart');

var _navLinks = [
  model.Link('analyse', 'Analyse', view.renderAnalyseTab),
  model.Link('settings', 'Settings', view.renderSettingsTab)
];
var _currentNavLink = _navLinks.first.pathname;

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
  for (var n in _navLinks) {
    view.appendNavLink(n.pathname, n.label, _currentNavLink == n.pathname);
  }

  await fb.init(
      'assets/firebase-constants.json', onLoginCompleted, onLogoutCompleted);
}

void onLoginCompleted() async {
  await loadDataFromDB();
  view.setNavlinkSelected(_currentNavLink);
  _navLinks.first.render();
}

void loadDataFromDB() async {
  view.showLoading();
  logger.debug('Read all required data');
  view.hideLoading();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
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
      _navLinks.firstWhere((n) => n.pathname == _currentNavLink).render();
      break;
    default:
  }
}
