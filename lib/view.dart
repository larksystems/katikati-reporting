import 'dart:html' as html;
import 'controller.dart';

const LOADING_MODAL_ID = 'loading-modal';

const LOGIN_MODAL_ID = 'login-modal';
const LOGIN_EMAIL_DOMAINS_SPAN_ID = 'login-email-domains';
const LOGIN_ERROR_ALERT_ID = 'login-error';
const LOGIN_BUTTON_ID = 'login-button';

const NAV_BRAND_ID = 'nav-brand';
const NAV_LINKS_WRAPPER_ID = 'nav-links-wrapper';
const NAV_ITEM_CSS_CLASSNAME = 'nav-item';
const ACTIVE_CSS_CLASSNAME = 'active';

const CONTENT_ID = 'content';

html.DivElement get loadingModal => html.querySelector('#${LOADING_MODAL_ID}');

html.DivElement get loginModal => html.querySelector('#${LOGIN_MODAL_ID}');
html.DivElement get loginEmailDomains =>
    html.querySelector('#${LOGIN_EMAIL_DOMAINS_SPAN_ID}');
html.DivElement get loginErrorAlert =>
    html.querySelector('#${LOGIN_ERROR_ALERT_ID}');
html.ButtonElement get loginButton => html.querySelector('#${LOGIN_BUTTON_ID}');

html.SpanElement get navBrand => html.querySelector('nav #${NAV_BRAND_ID}');
html.UListElement get navLinksWrapper =>
    html.querySelector('nav #${NAV_LINKS_WRAPPER_ID}');
List<html.LIElement> get navLinks => html.querySelectorAll(
    'nav #${NAV_LINKS_WRAPPER_ID} .${NAV_ITEM_CSS_CLASSNAME}');

html.DivElement get content => html.querySelector('#${CONTENT_ID}');

void init() {
  loginButton.onClick.listen((_) => command(UIAction.signinWithGoogle, null));
}

// Loading
void showLoading() {
  loadingModal.removeAttribute('hidden');
}

void hideLoading() {
  loadingModal.setAttribute('hidden', 'true');
}

// Login modal
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

// Nav bar
void setNavBrand(String text) {
  navBrand.innerText = text;
}

void appendNavLink(String pathname, String label, bool isSelected) {
  var li = html.LIElement()
    ..classes = [NAV_ITEM_CSS_CLASSNAME, if (isSelected) ACTIVE_CSS_CLASSNAME]
    ..innerText = label
    ..id = pathname
    ..onClick
        .listen((_) => command(UIAction.changeNavTab, NavChangeData(pathname)));
  navLinksWrapper.append(li);
}

void setNavlinkSelected(String id) {
  for (var link in navLinks) {
    link.classes.toggle(ACTIVE_CSS_CLASSNAME, link.getAttribute('id') == id);
  }
}

// Main content
void clearContentTab() {
  content.children.clear();
}

void renderAnalyseTab() {
  clearContentTab();
  content.append(html.DivElement()..innerText = 'Analyse');
}

void renderSettingsTab() {
  clearContentTab();
  content.append(html.DivElement()..innerText = 'Settings');
}

void render404() {
  clearContentTab();
  content.append(html.DivElement()..innerText = '404 page not found');
}
