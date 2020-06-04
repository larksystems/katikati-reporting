import 'dart:html' as html;

const LOCATION_EVENT_NAME = 'locationChanged';
const LOADING_MODAL_ID = 'loading-modal';
const LOGIN_MODAL_ID = 'login-modal';
const LOGIN_EMAIL_DOMAINS_SPAN_ID = 'login-email-domains';
const LOGIN_ERROR_ALERT_ID = 'login-error';
const LOGIN_BUTTON_ID = 'login-button';

html.DivElement get loadingModal => html.querySelector('#${LOADING_MODAL_ID}');
html.DivElement get loginModal => html.querySelector('#${LOGIN_MODAL_ID}');
html.DivElement get loginEmailDomains =>
    html.querySelector('#${LOGIN_EMAIL_DOMAINS_SPAN_ID}');
html.DivElement get loginErrorAlert =>
    html.querySelector('#${LOGIN_ERROR_ALERT_ID}');
html.ButtonElement get loginButton => html.querySelector('#${LOGIN_BUTTON_ID}');

// Route utils
String get currentPathname => html.window.location.pathname;

void gotoPath(String pathname, {bool replace = false}) {
  if (html.window.location.pathname == pathname) return;

  if (replace) {
    html.window.history.replaceState({}, '', pathname);
  } else {
    html.window.history.pushState({}, '', pathname);
  }

  html.window.dispatchEvent(html.Event(LOCATION_EVENT_NAME));
}

void listenToPathChanges(void Function(html.Event) callback) {
  html.window.addEventListener(LOCATION_EVENT_NAME, callback);
  html.window.onPopState.listen(callback);
}

// Modal utils
void showLoadingIndicator() {
  loadingModal.removeAttribute('hidden');
}

void hideLoadingIndicator() {
  loadingModal.setAttribute('hidden', 'true');
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
  loginErrorAlert.removeAttribute('hidden');
  loginErrorAlert.innerText = message;
}

void hideLoginError() {
  loginErrorAlert.innerText = '';
  loginErrorAlert.setAttribute('hidden', 'true');
}
