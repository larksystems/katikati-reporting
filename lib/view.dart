import 'dart:html' as html;
import 'controller.dart';
import 'package:chartjs/chartjs.dart' as chartjs;
import 'package:mapbox_gl_dart/mapbox_gl_dart.dart';
import 'package:dashboard/geomap_helpers.dart' as geomap_helpers;

const LOADING_MODAL_ID = 'loading-modal';

const LOGIN_MODAL_ID = 'login-modal';
const LOGIN_EMAIL_DOMAINS_SPAN_ID = 'login-email-domains';
const LOGIN_ERROR_ALERT_ID = 'login-error';
const LOGIN_BUTTON_ID = 'login-button';
const FILTERS_WRAPPER_ID = 'filters';

const NAV_BRAND_ID = 'nav-brand';
const NAV_LINKS_WRAPPER_ID = 'nav-links-wrapper';
const NAV_ITEM_CSS_CLASSNAME = 'nav-item';
const ACTIVE_CSS_CLASSNAME = 'active';
const CARD_CLASSNAME = 'card';
const CARD_BODY_CLASSNAME = 'card-body';
const CHART_WRAPPER_CLASSNAME = 'chart';
const MAPBOX_COL_CLASSNAME = 'mapbox-col';

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
html.DivElement get filtersWrapper =>
    html.querySelector('#${FILTERS_WRAPPER_ID}');
List<html.DivElement> get chartWrappers =>
    html.querySelectorAll('.${CHART_WRAPPER_CLASSNAME}');

String _generateFilterRowID(String key) => 'filter-row-${key}';
String _generateFilterDropdownID(String key) => 'filter-dropdown-${key}';
String _generateComparisonFilterDropdownID(String key) =>
    'comparison-filter-dropdown-${key}';
String _generateFilterCheckboxID(String key) => 'filter-option-${key}';
String _generateAnalyseTabID(String key) => 'analyse-tab-options-${key}';

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

void removeFiltersWrapper() {
  if (filtersWrapper == null) {
    logger
        .error('Trying to remove non-existant selector #${FILTERS_WRAPPER_ID}');
    return;
  }

  filtersWrapper.remove();
}

void removeAllChartWrappers() {
  for (var wrapper in chartWrappers) {
    if (wrapper == null) {
      logger.error(
          'Trying to remove non-existant selector .${CHART_WRAPPER_CLASSNAME}');
      continue;
    }
    wrapper.remove();
  }
}

html.DivElement generateGridRowElement({String id}) {
  var rowElement = html.DivElement()..classes = ['row'];
  if (id != null) {
    rowElement.id = id;
  }
  return rowElement;
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
      ..id = _generateAnalyseTabID(i.toString())
      ..classes = ['form-check-input']
      ..checked = i == 0
      ..onChange.listen((e) {
        if (!(e.target as html.RadioButtonInputElement).checked) return;
        command(UIAction.changeAnalysisTab, AnalysisTabChangeData(i));
      });
    var radioLabel = html.LabelElement()
      ..htmlFor = _generateAnalyseTabID(i.toString())
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

html.DivElement _getFilterRow(String filterKey) {
  var filterRowID = _generateFilterRowID(filterKey);
  return html.querySelector('#${filterRowID}') as html.DivElement;
}

void showFilterRow(String filterKey) {
  var filterRow = _getFilterRow(filterKey);
  if (filterRow.hidden != false) {
    filterRow.hidden = false;
  }
}

void hideFilterRow(String filterKey) {
  var filterRow = _getFilterRow(filterKey);
  if (filterRow.hidden != true) {
    filterRow.hidden = true;
  }
}

html.SelectElement _getFilterDropdown(String filterKey, {bool comparison}) {
  var dropdownID = comparison == true
      ? _generateComparisonFilterDropdownID(filterKey)
      : _generateFilterDropdownID(filterKey);
  return html.querySelector('#${dropdownID}') as html.SelectElement;
}

void enableFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown.disabled != false) {
    dropdown.disabled = false;
  }
}

void disableFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown.disabled != true) {
    dropdown.disabled = true;
  }
}

void hideFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown.hidden != true) {
    dropdown.hidden = true;
  }
}

void showFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown.hidden != false) {
    dropdown.hidden = false;
  }
}

void setFilterDropdownValue(String filterKey, String value, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  dropdown.value = value;
}

html.CheckboxInputElement _getFilterOptionCheckbox(String filterKey) {
  var filterCheckboxID = _generateFilterCheckboxID(filterKey);
  return html.querySelector('#${filterCheckboxID}')
      as html.CheckboxInputElement;
}

void enableFilterOption(String filterKey) {
  var filterCheckbox = _getFilterOptionCheckbox(filterKey);
  if (filterCheckbox.checked != true) {
    filterCheckbox.checked = true;
  }
}

void disableFilterOption(String filterKey) {
  var filterCheckbox = _getFilterOptionCheckbox(filterKey);
  if (filterCheckbox.checked != false) {
    filterCheckbox.checked = false;
  }
}

void renderFilterDropdowns(
    List<String> filterKeys,
    Map<String, List<String>> filterOptions,
    Set<String> activeKeys,
    Map<String, String> initialFilterValues,
    Map<String, String> initialFilterComparisonValues,
    bool shouldRenderComparisonFilters) {
  var wrapper = generateGridRowElement()..id = FILTERS_WRAPPER_ID;
  var labelCol = generateGridLabelColumnElement()..innerText = 'Filters';
  var optionsCol = generateGridOptionsColumnElement();

  for (var key in filterKeys) {
    var filterRow = generateGridRowElement(id: _generateFilterRowID(key));
    var checkboxCol = html.DivElement()..classes = ['col-3'];
    var filterCol = html.DivElement()..classes = ['col-3'];

    var checkboxWithLabel = _getCheckboxWithLabel(
        _generateFilterCheckboxID(key), key, activeKeys.contains(key),
        (bool checked) {
      command(
          UIAction.toggleActiveFilter, ToggleActiveFilterData(key, checked));
    });
    checkboxCol.append(checkboxWithLabel);

    var filterDropdown = _getDropdown(
        _generateFilterDropdownID(key),
        filterOptions[key].toList(),
        initialFilterValues[key],
        !activeKeys.contains(key), (String value) {
      command(UIAction.setFilterValue, SetFilterValueData(key, value));
    });
    filterCol.append(filterDropdown);

    filterRow.append(checkboxCol);
    filterRow.append(filterCol);
    optionsCol.append(filterRow);

    if (!shouldRenderComparisonFilters) continue;
    var comparisonFilterCol = html.DivElement()..classes = ['col-3'];

    var comparisonFilterDropdown = _getDropdown(
        _generateComparisonFilterDropdownID(key),
        filterOptions[key].toList(),
        initialFilterComparisonValues[key],
        !activeKeys.contains(key), (String value) {
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

void renderGeoMap(
    String id,
    String title,
    String narrative,
    dynamic mapData,
    Map<String, List<num>> mapFilterValues,
    Map<String, List<num>> mapComparisonFilterValues,
    bool comparisonEnabled,
    List<String> colors) {
  var mapPlaceholder =
      _generateGeoMapPlaceholder(title, narrative, id, comparisonEnabled);
  content.append(mapPlaceholder);

  var mapboxInstance = geomap_helpers.generateMapboxMap(mapData, id, false);
  mapboxInstance.on(
      'load',
      (_) =>
          handleMapLoad(mapboxInstance, mapData, mapFilterValues, colors[0]));

  if (comparisonEnabled) {
    var mapboxComparisonInstance =
        geomap_helpers.generateMapboxMap(mapData, id, true);
    mapboxComparisonInstance.on(
        'load',
        (_) => handleMapLoad(mapboxComparisonInstance, mapData,
            mapComparisonFilterValues, colors[1]));
  }
}

void handleMapLoad(MapboxMap mapInstance, dynamic mapData,
    Map<String, List<num>> mapValues, String fillColor) {
  for (var feature in mapData['features']) {
    var regionID = feature['properties']['regId'];
    var regionName = feature['properties']['regName'];
    mapInstance.addSource(regionID, {'type': 'geojson', 'data': feature});

    mapInstance.addLayer({
      'id': 'border-${regionID}',
      'type': 'line',
      'source': '${regionID}',
      'layout': {},
      'paint': {'line-width': 1, 'line-color': '#888'}
    });

    mapInstance.addLayer({
      'id': 'fill-${regionID}',
      'type': 'fill',
      'source': '${regionID}',
      'layout': {},
      'paint': {
        'fill-color': fillColor,
        'fill-opacity': (mapValues[regionID] ?? [0, 0])[1],
      }
    });

    if (mapValues[regionID] == null) continue;

    mapInstance.addLayer({
      'id': 'label-${regionID}',
      'type': 'symbol',
      'source': '${regionID}',
      'layout': {
        'text-field': '${regionName} (${mapValues[regionID][0]})',
        'text-size': 10,
      },
      'paint': {
        'text-color': '#000000',
        'text-halo-blur': 1,
        'text-halo-color': '#FFF',
        'text-halo-width': 2
      },
    });
  }
}

html.DivElement _generateBarChart(
    String title, String narrative, chartjs.ChartConfiguration chartConfig) {
  var wrapper = html.DivElement()..classes = [CHART_WRAPPER_CLASSNAME];

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

html.DivElement _generateGeoMapPlaceholder(
    String title, String narrative, String id, bool comparisonEnabled) {
  var wrapper = html.DivElement()..classes = [CHART_WRAPPER_CLASSNAME];

  var titleElement = html.HeadingElement.h5()..text = title;
  var narrativeElement = html.ParagraphElement()..text = narrative;
  wrapper.append(titleElement);
  wrapper.append(narrativeElement);

  var card = html.DivElement()..classes = [CARD_CLASSNAME];
  var cardBody = html.DivElement()..classes = [CARD_BODY_CLASSNAME];
  card.append(cardBody);

  var mapRow = generateGridRowElement();
  var mapCol = html.DivElement()
    ..classes = ['col', MAPBOX_COL_CLASSNAME]
    ..id = geomap_helpers.generateGeoMapID(id);
  mapRow.append(mapCol);

  if (comparisonEnabled) {
    var mapComparisonCol = html.DivElement()
      ..classes = ['col', MAPBOX_COL_CLASSNAME]
      ..id = geomap_helpers.generateGeoComparisonMapID(id);
    mapRow.append(mapComparisonCol);
  }

  cardBody.append(mapRow);

  wrapper.append(card);
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

html.SelectElement _getDropdown(String id, List<String> options,
    String selectedOption, bool disabled, Function(String) onChange) {
  var dropdownSelect = html.SelectElement()
    ..id = id
    ..classes = ['form-control']
    ..disabled = disabled
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
