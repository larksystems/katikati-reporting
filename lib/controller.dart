import 'view.dart';
import 'logger.dart';
import 'firebase.dart' as fb;
import 'package:firebase/firebase.dart' as firebase;
import 'firebase_constants.dart' as fb_constants;
import 'model.dart' as model;

Logger logger = Logger('app.dart');

class Controller {
  View view;
  String _activeNavTabID;

  // Misinfo messages
  List<model.Message> _misinfoMessages;

  // Interactions
  List<model.Interaction> _interactions;
  List<model.Interaction> _filteredInteractions;
  List<model.Interaction> _filteredCompareInteractions;

  bool _isCompareEnabled = true;
  String _activeInteractionTabID;

  List<model.InteractionFilter> _filters;
  List<model.Option> _themes;

  List<String> _activeFilters = [];
  Map<String, String> _filterValues = {};
  Map<String, String> _filterCompareValues = {};

  Controller(this._activeNavTabID, this.view) {
    initFirebase();
  }

  String get visibleTabID => _activeNavTabID;

  void initFirebase() async {
    await fb.init('firebase/constants.json');
    fb.firebaseAuth.onAuthStateChanged.listen(_fbAuthChanged);
    loginButton.onClick.listen((_) => fb.signInWithGoogle());
  }

  void _fbAuthChanged(firebase.User user) async {
    if (user == null) {
      logger.log('User not signedin');
      view.showLoginModal();
      return;
    }

    if (!fb_constants.allowedEmailDomains
        .any((domain) => user.email.endsWith(domain))) {
      logger.error('Email domain not allowed');
      await fb.deleteUser();
      view.showLoginError('Email domain not allowed');
      return;
    }

    if (!user.emailVerified) {
      logger.error('Email not verified');
      await fb.deleteUser();
      view.showLoginError('Email is not verified');
      return;
    }

    logger.log('Loggedin as ${user.email}');
    view.hideLoginModal();
    view.hideLoginError();
    _loadTab();
  }

  // Navigation tab
  void chooseNavTab(String tabID) {
    _activeNavTabID = tabID;
    _loadTab();
    renderView();
  }

  void _loadTab() async {
    view.showLoading();
    switch (_activeNavTabID) {
      case 'show-individuals':
        logger.log('Loading individuals');
        break;
      case 'show-misinfo':
        _misinfoMessages ??= await fb.readMisinfoMessages();
        sortMisinfoMessages(desc: true);
        view.setMessagesSortSelect(true);
        logger.log('Received ${_misinfoMessages.length} messages');
        renderMisinfoMessages();
        break;
      case 'show-interactions':
        logger.log('Loading interactions');
        _filters ??= await fb.readThemeFilters();
        _themes ??= await fb.readAllThemes();
        _interactions ??= await fb.readAllInteractions();
        logger.log('Received ${_interactions.length} interactions');
        setInteractionTab('theme');
        break;
      default:
        logger.error('No such tab');
    }
    view.hideLoading();
  }

  // Misinfo messages
  void sortMisinfoMessages({bool desc = true}) {
    _misinfoMessages.sort(
        (a, b) => (desc ? -1 : 1) * a.received_at.compareTo(b.received_at));
  }

  void renderMisinfoMessages() {
    view.renderMessagesTimeline(_misinfoMessages);
  }

  void renderView() {
    view.render();
  }

  // Interactions
  void enableCompare(bool isSelected) {
    _isCompareEnabled = isSelected;
    _renderInteractionFilters();
  }

  void _renderThemeFilters() {
    view.renderInteractionThemeFilters(_filters, _filterValues,
        _filterCompareValues, _activeFilters, _isCompareEnabled);
  }

  void _renderDemogFilters() {
    view.renderInteractionDemogThemes(_themes, _isCompareEnabled,
        _filterValues['theme'], _filterCompareValues['theme']);
    view.renderInteractionDemogFilters(_filters, _filterValues, _activeFilters);
  }

  void setInteractionTab(String tabID) {
    _activeFilters = [];
    _filterValues = {'theme': 'all'};
    _filterCompareValues = {'theme': 'all'};
    _activeInteractionTabID = tabID;
    _renderInteractionFilters();

    view.toggleInteractionTab(_activeInteractionTabID);
  }

  void _renderInteractionFilters() {
    switch (_activeInteractionTabID) {
      case 'theme':
        _renderThemeFilters();
        break;
      case 'demog':
        _renderDemogFilters();
        break;
      default:
        logger.error('No such tab to render filter');
    }
  }

  void addToActiveFilters(String theme) {
    logger.log('Add to active filter ${theme}');
    if (_activeFilters.contains(theme)) return;
    _activeFilters.add(theme);
    setFilterValue(theme, _filterValues[theme] ?? 'all');
    setFilterCompareValue(theme, _filterCompareValues[theme] ?? 'all');
    _renderInteractionFilters();

    _updateFilteredInteractions();
  }

  void removeFromActiveFilters(String theme) {
    logger.log('Remove from active filter ${theme}');
    if (!_activeFilters.contains(theme)) return;
    _activeFilters.removeWhere((t) => t == theme);
    _renderInteractionFilters();

    _updateFilteredInteractions();
  }

  void setFilterValue(String theme, String value) {
    _filterValues[theme] = value;
    logger.log('New filters are ${_filterValues}');
    _renderInteractionFilters();

    _updateFilteredInteractions();
  }

  void setFilterCompareValue(String theme, String value) {
    _filterCompareValues[theme] = value;
    logger.log('New filters compare are ${_filterValues}');
    _renderInteractionFilters();

    _updateFilteredInteractions();
  }

  List<model.Interaction> _getFilteredInteractions(
      Map<String, String> filterValues) {
    var interactions = List<model.Interaction>.from(_interactions);

    filterValues.forEach((key, value) {
      if (value != 'all' && _activeFilters.contains(key)) {
        switch (key) {
          case 'gender':
            interactions.removeWhere((i) => i.gender != value);
            break;
          case 'age':
            interactions.removeWhere((i) => i.age_bucket != value);
            break;
          case 'idp_status':
            interactions.removeWhere((i) => i.idp_status != value);
            break;
          case 'household_language':
            interactions.removeWhere((i) => i.household_language != value);
            break;
          case 'theme':
            interactions.removeWhere((i) => !i.themes.contains(value));
            break;
          default:
            logger.error('No such interaction filter');
        }
      }
    });

    return interactions;
  }

  void _updateFilteredInteractions() {
    logger.log(
        'Updating filtered values ${_filterValues} ${_filterCompareValues}');
    _filteredInteractions = _getFilteredInteractions(_filterValues);
    _filteredCompareInteractions =
        _getFilteredInteractions(_filterCompareValues);

    logger.log(
        'Filtered Interactions ${_filteredInteractions.length} & ${_filteredCompareInteractions.length}');
  }
}
