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

  bool _enableCompare = true;
  List<model.InteractionThemeFilter> _themeFilters;
  List<String> _activeThemeFilters = [];
  Map<String, String> _themeFilterValues = {};
  Map<String, String> _themeCompareFilterValues = {};

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
    _enableCompare = isSelected;
    _renderThemeFilters();
  }

  void _renderThemeFilters() {
    view.renderInteractionThemeFilters(_themeFilters, _themeFilterValues,
        _themeCompareFilterValues, _activeThemeFilters, _enableCompare);
  }

  void chooseInteractionThemes() {
    view.showInteractionAnalyseTheme();
    _renderThemeFilters();
  }

  void chooseInteractionDemographics() {
    view.showInteractionAnalyseDemographics();
  }

  void addToActiveThemeFilters(String theme) {
    if (_activeThemeFilters.contains(theme)) return;
    _activeThemeFilters.add(theme);
    chooseInteractionThemeFilter(theme, _themeFilterValues[theme] ?? 'all');
    chooseInteractionCompareThemeFilter(
        theme, _themeCompareFilterValues[theme] ?? 'all');
  }

  void removeFromActiveFilters(String theme) {
    if (!_activeThemeFilters.contains(theme)) return;
    _activeThemeFilters.removeWhere((t) => t == theme);
    _renderThemeFilters();
  }

  void chooseInteractionThemeFilter(String theme, String value) {
    _themeFilterValues[theme] = value;
    _renderThemeFilters();
  }

  void chooseInteractionCompareThemeFilter(String theme, String value) {
    _themeCompareFilterValues[theme] = value;
    _renderThemeFilters();
  }
}
