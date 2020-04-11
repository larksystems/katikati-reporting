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
  bool _isCompareEnabled = true;
  String _activeInteractionTabID;

  List<model.InteractionFilter> _filters;
  List<model.Option> _themes;

  List<String> _activeFilters = [];
  Map<String, String> _filterValues = {};
  Map<String, String> _filterCompareValues = {};

  String _themeValue;
  String _themeCompareValue;

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
    view.renderInteractionDemogThemes(
        _themes, _isCompareEnabled, _themeValue, _themeCompareValue);
    view.renderInteractionDemogFilters(_filters, _filterValues, _activeFilters);
  }

  void setInteractionTab(String tabID) {
    _activeFilters = [];
    _filterValues = {};
    _filterCompareValues = {};
    _themeValue = null;
    _themeCompareValue = null;
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

  void setThemeValue(String theme) {
    _themeValue = theme;
    _renderDemogFilters();
  }

  void setThemeCompareValue(String theme) {
    _themeCompareValue = theme;
    _renderDemogFilters();
  }

  void addToActiveFilters(String theme) {
    if (_activeFilters.contains(theme)) return;
    _activeFilters.add(theme);
    setFilterValue(theme, _filterValues[theme] ?? 'all');
    setFilterCompareValue(theme, _filterCompareValues[theme] ?? 'all');
    _renderInteractionFilters();
  }

  void removeFromActiveFilters(String theme) {
    if (!_activeFilters.contains(theme)) return;
    _activeFilters.removeWhere((t) => t == theme);
    _renderInteractionFilters();
  }

  void setFilterValue(String theme, String value) {
    _filterValues[theme] = value;
    _renderInteractionFilters();
  }

  void setFilterCompareValue(String theme, String value) {
    _filterCompareValues[theme] = value;
    _renderInteractionFilters();
  }
}
