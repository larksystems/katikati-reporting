import 'dart:html' as html;
import 'package:dashboard/login/controller.dart';

const LOGIN_MODAL_ID = 'login-modal';
const LOGIN_EMAIL_DOMAINS_SPAN_ID = 'login-email-domains';
const LOGIN_ERROR_ALERT_ID = 'login-error';
const LOGIN_BUTTON_ID = 'login-button';

html.DivElement get loginModal => html.querySelector('#${LOGIN_MODAL_ID}');
html.DivElement get loginEmailDomains =>
    html.querySelector('#${LOGIN_EMAIL_DOMAINS_SPAN_ID}');
html.DivElement get loginErrorAlert =>
    html.querySelector('#${LOGIN_ERROR_ALERT_ID}');
html.ButtonElement get loginButton => html.querySelector('#${LOGIN_BUTTON_ID}');

class View {
  Controller controller;

  View(this.controller) {
    loginButton.onClick.listen((_) {
      disableLoginButton();
      controller.command(UIAction.signinWithGoogle);
    });
  }

  void showLoginModal() {
    loginModal.removeAttribute('hidden');
  }

  void hideLoginModal() {
    loginModal.setAttribute('hidden', 'true');
  }

  void setLoginDomains(List<String> domains) {
    loginEmailDomains.innerText = domains.join(', ');
  }

  void enableLoginButton() {
    loginButton.removeAttribute('disabled');
    loginButton.innerText = 'Sign in with Google';
  }

  void disableLoginButton() {
    loginButton.setAttribute('disabled', 'true');
    loginButton.innerText = 'Signing in ...';
  }

  void showLoginError(String message) {
    loginErrorAlert.innerText = message;
    loginErrorAlert.removeAttribute('hidden');
  }

  void hideLoginError() {
    loginErrorAlert.innerText = '';
    loginErrorAlert.setAttribute('hidden', 'true');
  }
}
