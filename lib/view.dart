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
  loadingModal.hidden = false;
}

void hideLoading() {
  loadingModal.hidden = true;
}

// Login modal
void showLoginModal() {
  loginModal.hidden = false;
}

void hideLoginModal() {
  loginModal.hidden = true;
}

void setLoginDomains(List<String> domains) {
  loginEmailDomains.innerText = domains.join(', ');
}

void enableLoginButton() {
  loginButton.disabled = false;
  loginButton.innerText = 'Sign in with Google';
}

void disableLoginButton() {
  loginButton.disabled = true;
  loginButton.innerText = 'Signing in ...';
}

void showLoginError(String message) {
  loginErrorAlert.innerText = message;
  loginErrorAlert.hidden = false;
}

void hideLoginError() {
  loginErrorAlert.innerText = '';
  loginErrorAlert.hidden = true;
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

html.DivElement getRowDiv() {
  return html.DivElement()..classes = ['row'];
}

html.DivElement getLabelColDiv() {
  return html.DivElement()
    ..classes = ['col-lg-2', 'col-md-3', 'col-sm-12', 'col-xs-12'];
}

html.DivElement getOptionsColDiv() {
  return html.DivElement()
    ..classes = ['col-lg-10', 'col-md-9', 'col-sm-12', 'col-xs-12'];
}

void renderAnalysisTabs(List<String> labels) {
  var wrapper = getRowDiv();
  var labelCol = getLabelColDiv()..innerText = 'Analyse';
  var optionsCol = getOptionsColDiv();

  for (var i = 0; i < labels.length; ++i) {
    var radioWrapper = html.DivElement()
      ..classes = ['form-check', 'form-check-inline'];
    var radioOption = html.InputElement()
      ..type = 'radio'
      ..name = 'analyse-tab-options'
      ..id = 'analyse-tab-options-${i}'
      ..classes = ['form-check-input']
      ..checked = i == 0
      ..onChange.listen((e) {
        if (!(e.target as html.RadioButtonInputElement).checked) return;
        command(UIAction.changeAnalysisTab, AnalysisTabChangeData(i));
      });
    var radioLabel = html.LabelElement()
      ..htmlFor = 'analyse-tab-options-${i}'
      ..classes = ['form-check-label']
      ..innerText = labels[i];

    radioWrapper.append(radioOption);
    radioWrapper.append(radioLabel);
    optionsCol.append(radioWrapper);
  }

  wrapper.append(labelCol);
  wrapper.append(optionsCol);
  content.append(wrapper);
}

void renderChartOptions(bool isComparisonChecked, bool isNormalisationChecked) {
  var wrapper = getRowDiv();
  var labelCol = getLabelColDiv()..innerText = 'Options';
  var optionsCol = getOptionsColDiv();

  var comparisonWrapper = html.DivElement()
    ..classes = ['form-check', 'form-check-inline'];
  var comparisonOption = html.InputElement()
    ..type = 'checkbox'
    ..id = 'comparison-option'
    ..classes = ['form-check-input']
    ..checked = isComparisonChecked
    ..onChange.listen((e) {
      command(UIAction.toggleDataComparison,
          ToggleData((e.target as html.CheckboxInputElement).checked));
    });
  var comparisonLabel = html.LabelElement()
    ..htmlFor = 'comparison-option'
    ..classes = ['form-check-label']
    ..innerText = 'Compare data';
  comparisonWrapper.append(comparisonOption);
  comparisonWrapper.append(comparisonLabel);
  optionsCol.append(comparisonWrapper);

  var normalisationWrapper = html.DivElement()
    ..classes = ['form-check', 'form-check-inline'];
  var normalisationOption = html.InputElement()
    ..type = 'checkbox'
    ..id = 'normalisation-option'
    ..classes = ['form-check-input']
    ..checked = isNormalisationChecked
    ..onChange.listen((e) {
      command(UIAction.toggleDataNormalisation,
          ToggleData((e.target as html.CheckboxInputElement).checked));
    });
  var normalisationLabel = html.LabelElement()
    ..htmlFor = 'normalisation-option'
    ..classes = ['form-check-label']
    ..innerText = 'Normalise data';
  normalisationWrapper.append(normalisationOption);
  normalisationWrapper.append(normalisationLabel);
  optionsCol.append(normalisationWrapper);

  wrapper.append(labelCol);
  wrapper.append(optionsCol);
  content.append(wrapper);
}

void renderSettingsTab() {
  clearContentTab();
  content.append(html.DivElement()..innerText = 'Settings');
}

void render404() {
  clearContentTab();
  content.append(html.DivElement()..innerText = '404 page not found');
}

void showAlert(String message) {
  html.window.alert('Error: ${message}');
}
