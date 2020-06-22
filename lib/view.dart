import 'dart:html' as html;
import 'controller.dart';
import 'package:chartjs/chartjs.dart' as chartjs;

const LOADING_MODAL_ID = 'loading-modal';

const LOGIN_MODAL_ID = 'login-modal';
const LOGIN_EMAIL_DOMAINS_SPAN_ID = 'login-email-domains';
const LOGIN_ERROR_ALERT_ID = 'login-error';
const LOGIN_BUTTON_ID = 'login-button';

const NAV_BRAND_ID = 'nav-brand';
const NAV_LINKS_WRAPPER_ID = 'nav-links-wrapper';
const NAV_ITEM_CSS_CLASSNAME = 'nav-item';
const ACTIVE_CSS_CLASSNAME = 'active';
const CARD_CLASSNAME = 'card';
const CARD_BODY_CLASSNAME = 'card-body';

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

void appendNavLink(String pathname, String label, bool selected) {
  var li = html.LIElement()
    ..classes = [NAV_ITEM_CSS_CLASSNAME, if (selected) ACTIVE_CSS_CLASSNAME]
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

html.DivElement generateGridRowElement() {
  return html.DivElement()..classes = ['row'];
}

html.DivElement generateGridLabelColumnElement() {
  return html.DivElement()
    ..classes = ['col-lg-2', 'col-md-3', 'col-sm-12', 'col-xs-12'];
}

html.DivElement generateGridOptionsColumnElement() {
  return html.DivElement()
    ..classes = ['col-lg-10', 'col-md-9', 'col-sm-12', 'col-xs-12'];
}

void renderAnalysisTabs(List<String> labels) {
  var wrapper = generateGridRowElement();
  var labelCol = generateGridLabelColumnElement()..innerText = 'Analyse';
  var optionsCol = generateGridOptionsColumnElement();

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

void renderChartOptions(bool comparisonEnabled, bool normalisationEnabled) {
  var wrapper = generateGridRowElement();
  var labelCol = generateGridLabelColumnElement()..innerText = 'Options';
  var optionsCol = generateGridOptionsColumnElement();

  var comparisonCheckbox = _getCheckboxWithLabel(
      'comparison-option', 'Compare data', comparisonEnabled, (bool checked) {
    command(UIAction.toggleDataComparison, ToggleOptionEnabledData(checked));
  });
  optionsCol.append(comparisonCheckbox);

  var normalisationCheckbox = _getCheckboxWithLabel(
      'normalisation-option', 'Normalise data', normalisationEnabled,
      (bool checked) {
    command(UIAction.toggleDataNormalisation, ToggleOptionEnabledData(checked));
  });
  optionsCol.append(normalisationCheckbox);

  wrapper.append(labelCol);
  wrapper.append(optionsCol);
  content.append(wrapper);
}

void renderFilterDropdowns(
    List<String> filterKeys,
    Map<String, List<String>> filterOptions,
    bool shouldRenderComparisonFilters) {
  var wrapper = generateGridRowElement();
  var labelCol = generateGridLabelColumnElement()..innerText = 'Filters';
  var optionsCol = generateGridOptionsColumnElement();

  for (var key in filterKeys) {
    var filterRow = generateGridRowElement();
    var checkboxCol = html.DivElement()..classes = ['col-3'];
    var filterCol = html.DivElement()..classes = ['col-3'];

    var checkboxWithLabel = _getCheckboxWithLabel(
        'filter-option-${key}', key, false, (bool checked) {
      command(
          UIAction.toggleActiveFilter, ToggleActiveFilterData(key, checked));
    });
    checkboxCol.append(checkboxWithLabel);

    var filterDropdown =
        _getDropdown(filterOptions[key].toList(), '__all', (String value) {
      command(UIAction.setFilterValue, SetFilterValueData(key, value));
    });
    filterCol.append(filterDropdown);

    filterRow.append(checkboxCol);
    filterRow.append(filterCol);
    optionsCol.append(filterRow);

    if (!shouldRenderComparisonFilters) continue;
    var comparisonFilterCol = html.DivElement()..classes = ['col-3'];
    // todo: remove __all hardcoding
    var comparisonFilterDropdown =
        _getDropdown(filterOptions[key].toList(), '__all', (String value) {
      command(
          UIAction.setComparisonFilterValue, SetFilterValueData(key, value));
    });
    comparisonFilterCol.append(comparisonFilterDropdown);
    filterRow.append(comparisonFilterCol);
  }

  wrapper.append(labelCol);
  wrapper.append(optionsCol);
  content.append(wrapper);
}

void renderBarChart(
    String title, String narrative, chartjs.ChartConfiguration chartConfig) {
  var chart = _generateBarChart(title, narrative, chartConfig);
  content.append(chart);
}

html.DivElement _generateBarChart(
    String title, String narrative, chartjs.ChartConfiguration chartConfig) {
  var wrapper = html.DivElement();

  var titleElement = html.HeadingElement.h5()..text = title;
  var narrativeElement = html.ParagraphElement()..text = narrative;
  wrapper.append(titleElement);
  wrapper.append(narrativeElement);

  var card = html.DivElement()..classes = [CARD_CLASSNAME];
  var cardBody = html.DivElement()..classes = [CARD_BODY_CLASSNAME];
  card.append(cardBody);

  var canvas = html.CanvasElement();
  cardBody.append(canvas);
  wrapper.append(card);

  chartjs.Chart(canvas, chartConfig);

  return wrapper;
}

html.DivElement _getCheckboxWithLabel(
    String id, String label, bool checked, Function(bool) onChange) {
  var checkboxWrapper = html.DivElement()
    ..classes = ['form-check', 'form-check-inline'];
  var checkboxOption = html.InputElement()
    ..type = 'checkbox'
    ..id = id
    ..classes = ['form-check-input']
    ..checked = checked
    ..onChange.listen(
        (e) => onChange((e.target as html.CheckboxInputElement).checked));
  var checkboxLabel = html.LabelElement()
    ..htmlFor = id
    ..classes = ['form-check-label']
    ..innerText = label;
  checkboxWrapper.append(checkboxOption);
  checkboxWrapper.append(checkboxLabel);
  return checkboxWrapper;
}

html.SelectElement _getDropdown(
    List<String> options, String selectedOption, Function(String) onChange) {
  var dropdownSelect = html.SelectElement()
    ..classes = ['form-control']
    ..onChange.listen((e) => onChange((e.target as html.SelectElement).value));

  for (var option in options) {
    var dropdownOption = html.OptionElement()
      ..value = option
      ..selected = option == selectedOption
      ..text = option;
    dropdownSelect.append(dropdownOption);
  }

  return dropdownSelect;
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
