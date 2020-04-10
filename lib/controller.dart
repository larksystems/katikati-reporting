import 'view.dart';
import 'logger.dart';
import 'firebase.dart' as fb;
import 'package:firebase/firebase.dart' as firebase;
import 'firebase_constants.dart' as fb_constants;
import 'model.dart' as model;

Logger logger = Logger('app.dart');

class Controller {
  View view;
  String _visibleTabID;

  List<model.Message> _messages;

  bool _isCompareEnabled = true;
  bool _isThemesVisible = true;
  String _demogTheme;
  String _demogCompareTheme;
  List<model.Option> _allThemes;
  List<model.InteractionFilter> _themeFilters;
  List<String> _activeFilters = [];
  Map<String, String> _filterValues = {};
  Map<String, String> _compareFilterValues = {};

  Controller(this._visibleTabID, this.view) {
    initFirebase();
  }

  String get visibleTabID => _visibleTabID;

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

  void chooseTab(String tabID) {
    _visibleTabID = tabID;
    _loadTab();
    renderView();
  }

  void sortMessages({bool desc = true}) {
    _messages.sort(
        (a, b) => (desc ? -1 : 1) * a.received_at.compareTo(b.received_at));
  }

  void _loadTab() async {
    view.showLoading();
    switch (_visibleTabID) {
      case 'show-individuals':
        logger.log('Loading individuals');
        break;
      case 'show-misinfo':
        _messages ??= await fb.readMisinfoMessages();
        sortMessages(desc: true);
        view.updateMessagesSort(true);
        logger.log('Received ${_messages.length} messages');
        renderMessages();
        break;
      case 'show-interactions':
        logger.log('Loading interactions');
        _themeFilters ??= await fb.readThemeFilters();
        _allThemes ??= await fb.readAllThemes();
        chooseInteractionThemes();
        break;
      default:
        logger.error('No such tab');
    }
    view.hideLoading();
  }

  void renderMessages() {
    view.renderMessagesTimeline(_messages);
  }

  void renderView() {
    view.render();
  }

  void enableCompare(bool isSelected) {
    _isCompareEnabled = isSelected;
    _renderThemeFilters();
  }

  void _renderThemeFilters() {
    view.renderInteractionThemeFilters(_themeFilters, _filterValues,
        _compareFilterValues, _activeFilters, _isCompareEnabled);
  }

  void _renderDemogFilters() {
    view.renderInteractionDemogFilters(
        _themeFilters, _filterValues, _activeFilters);
  }

  void chooseInteractionThemes() {
    _isThemesVisible = true;
    view.showInteractionAnalyseTheme();
    _activeFilters = [];
    _filterValues = {};
    _compareFilterValues = {};
    _renderThemeFilters();
  }

  void chooseInteractionDemographics() {
    _isThemesVisible = false;
    view.showInteractionAnalyseDemographics();
    _activeFilters = [];
    _filterValues = {};
    _compareFilterValues = {};
    print(_allThemes);
    _renderDemogThemes();
    _renderDemogFilters();
  }

  void _renderDemogThemes() {
    view.renderInteractionDemogThemes(
        _allThemes, _isCompareEnabled, _demogTheme, _demogCompareTheme);
  }

  void chooseDemogTheme(String theme) {
    _demogTheme = theme;
    _renderDemogThemes();
  }

  void chooseDemogCompareTheme(String theme) {
    _demogCompareTheme = theme;
    _renderDemogThemes();
  }

  void addToActiveThemeFilters(String theme) {
    if (_activeFilters.contains(theme)) return;
    _activeFilters.add(theme);
    chooseInteractionThemeFilter(theme, _filterValues[theme] ?? 'all');
    chooseInteractionCompareThemeFilter(
        theme, _compareFilterValues[theme] ?? 'all');
  }

  void removeFromActiveFilters(String theme) {
    if (!_activeFilters.contains(theme)) return;
    _activeFilters.removeWhere((t) => t == theme);

    if (_isThemesVisible) {
      _renderThemeFilters();
    } else {
      _renderDemogFilters();
    }
  }

  void chooseInteractionThemeFilter(String theme, String value) {
    _filterValues[theme] = value;
    if (_isThemesVisible) {
      _renderThemeFilters();
    } else {
      _renderDemogFilters();
    }
  }

  void chooseInteractionCompareThemeFilter(String theme, String value) {
    _compareFilterValues[theme] = value;
    if (_isThemesVisible) {
      _renderThemeFilters();
    } else {
      _renderDemogFilters();
      _renderDemogThemes();
    }
  }
}
