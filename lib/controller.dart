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

Map<String, String> _errorMessages = {
  'parse-config': 'Unable to parse "Config" to the required format',
  'fetch-interactions': 'Unable to fetch interactions'
};

var _currentNavLink = _navLinks['analyse'].pathname;

// UI States
String _selectedTab;
bool _isCompareEnabled = true;
bool _isChartsNormalisedEnabled = false;
List<String> _activeFilters = [];
Map<String, String> _filterValues = {};
Map<String, String> _filterComparisionValues = {};

// Data states
Map<String, Map<String, dynamic>> _allInteractions;
Map<String, Map<String, dynamic>> _filteredInteractions;
Map<String, Map<String, dynamic>> _filteredComparisonInteractions;
Map<String, Set> _uniqueFieldValues;
model.Config _config;
List<model.Chart> _charts;

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
  view.showLoading();

  await loadDataFromFirebase();
  _filteredInteractions = _allInteractions;
  _filteredComparisonInteractions = _allInteractions;

  computeUniqFieldValues();
  _selectedTab = _config.tabs.first.id;

  view.setNavlinkSelected(_currentNavLink);
  _navLinks['analyse'].render();

  view.hideLoading();
}

void onLogoutCompleted() async {
  logger.debug('Delete all local data');
}

void loadDataFromFirebase() async {
  try {
    _config = await fb.fetchConfig();
  } catch (e) {
    view.showAlert(_errorMessages['parse-config']);
    logger.error(e);
    rethrow;
  }

  try {
    _allInteractions =
        await fb.fetchInteractions(_config.data_paths['interactions']);
  } catch (e) {
    view.showAlert(_errorMessages['fetch-interactions']);
    logger.error(e);
    rethrow;
  }
}

void computeUniqFieldValues() {
  _uniqueFieldValues = Map<String, Set>();
  _config.filters.forEach((filter) {
    _uniqueFieldValues[filter.key] = Set();
  });

  _allInteractions.forEach((_, interaction) {
    _uniqueFieldValues.forEach((key, valueSet) {
      var value = interaction[key];
      (value is List) ? valueSet.addAll(value) : valueSet.add(value);
    });
  });

  logger.debug('Computed unique field values for all filters');
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
