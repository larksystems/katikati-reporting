import 'package:firebase/firebase.dart' as firebase;
import 'package:dashboard/login/view.dart' as login_view;
import 'package:dashboard/firebase.dart' as fb;
import 'package:dashboard/logger.dart';

Logger logger = Logger('loginModal/controller.dart');

enum UIAction { signinWithGoogle }

class Controller {
  login_view.View _view;
  final void Function() _onLoginCallback;
  final void Function() _onLogoutCallback;

  Controller(this._onLoginCallback, this._onLogoutCallback) {
    _view = login_view.View(this);
    _initialRender();
    _initFirebase();
  }

  void _initialRender() {
    _view.showLoginModal();
  }

  void _initFirebase() async {
    await fb.init('assets/firebase-constants.json');
    _view.setLoginDomains(fb.allowedEmailDomains);
    fb.firebaseAuth.onAuthStateChanged.listen(_fbAuthChanged);
  }

  void _fbAuthChanged(firebase.User user) async {
    _view.enableLoginButton();
    if (user == null) {
      logger.debug('User not signed in');
      _view.showLoginModal();
      if (_onLogoutCallback != null) _onLogoutCallback();
      return;
    }

    if (!fb.allowedEmailDomains.any((domain) => user.email.endsWith(domain))) {
      logger.error('Email domain not allowed');
      await fb.deleteUser();
      _view.showLoginError('Email domain not allowed');
      return;
    }

    if (!user.emailVerified) {
      logger.error('Email not verified');
      await fb.deleteUser();
      _view.showLoginError('Email is not verified');
      return;
    }

    logger.debug('Loggedin as ${user.email}');
    _view.hideLoginError();
    _view.hideLoginModal();

    if (_onLoginCallback != null) _onLoginCallback();
  }

  void command(UIAction action) {
    switch (action) {
      case UIAction.signinWithGoogle:
        fb.signInWithGoogle();
        break;
      default:
    }
  }
}
