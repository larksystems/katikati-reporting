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
    switch (_visibleTabID) {
      case 'show-individuals':
        logger.log('Loading individuals');
        break;
      case 'show-misinfo':
        view.showLoading();
        _messages = await fb.readMisinfoMessages();
        sortMessages(desc: true);
        logger.log('Received ${_messages.length} messages');
        renderMessages();
        view.hideLoading();
        break;
      case 'show-interactions':
        logger.log('Loading interactions');
        break;
      default:
        logger.error('No such tab');
    }
  }

  void renderMessages() {
    view.renderMessagesTimeline(_messages);
  }

  void renderView() {
    view.render();
  }
}
