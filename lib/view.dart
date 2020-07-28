import 'dart:html' as html;
import 'dart:svg' as svg;
import 'package:uuid/uuid.dart';
import 'controller.dart';
import 'package:dashboard/model.dart' as model;
import 'package:chartjs/chartjs.dart' as chartjs;
import 'package:mapbox_gl_dart/mapbox_gl_dart.dart';
import 'package:dashboard/geomap_helpers.dart' as geomap_helpers;
import 'package:codemirror/codemirror.dart' as code_mirror;

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
const FILTER_ROW_CLASSNAME = 'filter-row';
const FILTER_ROW_LABEL_CLASSNAME = 'filter-row-label';
const CARD_CLASSNAME = 'card';
const CARD_BODY_CLASSNAME = 'card-body';
const CHART_WRAPPER_CLASSNAME = 'chart';
const MAPBOX_COL_CLASSNAME = 'mapbox-col';
const CONFIG_SETTINGS_ALERT_ID = 'config-settings-alert';
const CONFIG_UNIQUE_VALUES_WRAPPER_CLASSNAME = 'unique-values-wrapper';

const CONTENT_ID = 'content';

var uuid = Uuid();

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
html.DivElement get configSettingsAlert =>
    html.querySelector('#${CONFIG_SETTINGS_ALERT_ID}');

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

html.DivElement generateGridRowElement({String id, List<String> classes}) {
  var rowElement = html.DivElement()..classes = ['row', ...(classes ?? [])];
  if (id != null) {
    rowElement.id = id;
  }
  return rowElement;
}

html.DivElement generateGridLabelColumnElement({List<String> classes}) {
  return html.DivElement()
    ..classes = [
      'col-lg-2',
      'col-md-3',
      'col-sm-12',
      'col-xs-12',
      ...(classes ?? [])
    ];
}

html.DivElement generateGridOptionsColumnElement() {
  return html.DivElement()
    ..classes = ['col-lg-10', 'col-md-9', 'col-sm-12', 'col-xs-12'];
}

void renderAnalysisTabs(List<String> labels, int selectedIndex) {
  var wrapper = generateGridRowElement(classes: [FILTER_ROW_CLASSNAME]);
  var labelCol =
      generateGridLabelColumnElement(classes: [FILTER_ROW_LABEL_CLASSNAME])
        ..innerText = 'Analyse';
  var optionsCol = generateGridOptionsColumnElement();

  for (var i = 0; i < labels.length; ++i) {
    var radioWrapper = html.DivElement()
      ..classes = ['form-check', 'form-check-inline'];
    var radioOption = html.InputElement()
      ..type = 'radio'
      ..name = 'analyse-tab-options'
      ..id = _generateAnalyseTabID(i.toString())
      ..classes = ['form-check-input']
      ..checked = i == selectedIndex
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

void renderChartOptions(bool comparisonEnabled, bool normalisationEnabled,
    bool stackTimeseriesEnabled) {
  var wrapper = generateGridRowElement(classes: [FILTER_ROW_CLASSNAME]);
  var labelCol =
      generateGridLabelColumnElement(classes: [FILTER_ROW_LABEL_CLASSNAME])
        ..innerText = 'Options';
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

  var stackTimeseriesCheckbox = _getCheckboxWithLabel(
      'stack-timeseries',
      'Stack time series',
      stackTimeseriesEnabled,
      (bool checked) => command(
          UIAction.toggleStackTimeseries, ToggleOptionEnabledData(checked)));
  optionsCol.append(stackTimeseriesCheckbox);

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
  if (dropdown == null) {
    return;
  }
  if (dropdown.disabled != false) {
    dropdown.disabled = false;
  }
}

void disableFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown == null) {
    return;
  }
  if (dropdown.disabled != true) {
    dropdown.disabled = true;
  }
}

void hideFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown == null) {
    return;
  }
  if (dropdown.hidden != true) {
    dropdown.hidden = true;
  }
}

void showFilterDropdown(String filterKey, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown == null) {
    return;
  }
  if (dropdown.hidden != false) {
    dropdown.hidden = false;
  }
}

void setFilterDropdownValue(String filterKey, String value, {bool comparison}) {
  var dropdown = _getFilterDropdown(filterKey, comparison: comparison);
  if (dropdown == null) {
    return;
  }
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
  var wrapper = generateGridRowElement(classes: [FILTER_ROW_CLASSNAME])
    ..id = FILTERS_WRAPPER_ID;
  var labelCol =
      generateGridLabelColumnElement(classes: [FILTER_ROW_LABEL_CLASSNAME])
        ..innerText = 'Filters';
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

void renderChart(
    String title, String narrative, chartjs.ChartConfiguration chartConfig) {
  var chart = _generateChart(title, narrative, chartConfig);
  content.append(chart);
}

void renderFunnelChart(
    String title, String narrative, model.FunnelChartConfig chartConfig) {
  var chart = _generateFunnelChart(title, narrative, chartConfig);
  content.append(chart);
}

html.DivElement _generateFunnelChart(
    String title, String narrative, model.FunnelChartConfig chartConfig) {
  var wrapper = html.DivElement()..classes = [CHART_WRAPPER_CLASSNAME];

  var titleElement = html.HeadingElement.h5()..text = title;
  var narrativeElement = html.ParagraphElement()..text = narrative;
  wrapper.append(titleElement);
  wrapper.append(narrativeElement);

  var card = html.DivElement()..classes = [CARD_CLASSNAME];
  var cardBody = html.DivElement()..classes = [CARD_BODY_CLASSNAME];
  card.append(cardBody);
  wrapper.append(card);

  var maxDataValue = chartConfig.data.first.value;
  var chartHeight = 360;
  var maxHeight = 300;
  var width = 96;
  var xOffset = 30;
  var yOffset = 30;
  var increment = chartConfig.isParied ? 2 : 1;
  var colorsIndex = 0;
  var defaultOpacity = '0.8';
  var hoverOpacity = '1.0';

  var svgWrapper = svg.SvgSvgElement()
    ..setAttribute('width', '100%')
    ..setAttribute('height', chartHeight.toString());

  for (var i = 0; i < chartConfig.data.length - 1; i = i + increment) {
    var curr = chartConfig.data[i].value;
    var next = chartConfig.data[i + 1].value;

    var leftHeight = curr / maxDataValue * maxHeight;
    var leftDiff = yOffset + (maxHeight - leftHeight) / 2;
    var rightHeight = next / maxDataValue * maxHeight;
    var rightDiff = (maxHeight - rightHeight) / 2 + yOffset;
    var leftOffset = xOffset + (i / 2) * width;

    var x1 = leftOffset;
    var y1 = leftDiff;
    var x2 = leftOffset;
    var y2 = leftDiff + leftHeight;
    var x3 = leftOffset + width;
    var y3 = rightDiff + rightHeight;
    var x4 = leftOffset + width;
    var y4 = rightDiff;

    var points = ['$x1,$y1', '$x2,$y2', '$x3,$y3', '$x4,$y4'];

    var topLabel = svg.TextElement()
      ..setAttribute('x', x1.toString())
      ..setAttribute('y', (y1 - 4).toString())
      ..setAttribute('font-size', '12px')
      ..setAttribute('visibility', 'hidden')
      ..innerHtml =
          '${chartConfig.data[i].label} (${chartConfig.data[i].value})';
    var bottomLabel = svg.TextElement()
      ..setAttribute('x', x3.toString())
      ..setAttribute('y', (y3 + 12).toString())
      ..setAttribute('font-size', '12px')
      ..setAttribute('visibility', 'hidden')
      ..innerHtml =
          '${chartConfig.data[i + 1].label} (${chartConfig.data[i + 1].value})';

    var percent = ((next - curr) * 100 / curr).round();
    var percentLabel = svg.TextElement()
      ..setAttribute('x', ((x1 + x4) / 2).toString())
      ..setAttribute('y', ((y3 + y4) / 2 + 6).toString())
      ..setAttribute('font-size', '12px')
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('pointer-events', 'none')
      ..innerHtml = '${percent}%';

    var funnel = svg.PolygonElement()
      ..setAttribute('points', points.join(' '))
      ..setAttribute('fill', chartConfig.colors[colorsIndex++])
      ..setAttribute('opacity', defaultOpacity)
      ..onMouseEnter.listen((event) {
        topLabel.setAttribute('visibility', 'visible');
        bottomLabel.setAttribute('visibility', 'visible');
        (event.target as svg.PolygonElement)
            .setAttribute('opacity', hoverOpacity);
      })
      ..onMouseLeave.listen((event) {
        topLabel.setAttribute('visibility', 'hidden');
        bottomLabel.setAttribute('visibility', 'hidden');
        (event.target as svg.PolygonElement)
            .setAttribute('opacity', defaultOpacity);
      });

    svgWrapper.append(funnel);
    svgWrapper.append(topLabel);
    svgWrapper.append(bottomLabel);
    svgWrapper.append(percentLabel);
  }

  if (chartConfig.isParied) {
    if (chartConfig.data.length.isOdd) {
      var leftHeight = chartConfig.data.last.value / maxDataValue * maxHeight;
      var leftDiff = (maxHeight - leftHeight) / 2 + yOffset;
      var leftOffset = xOffset + ((chartConfig.data.length - 1) / 2) * width;
      var points = [
        '$leftOffset,$leftDiff',
        '$leftOffset,${leftDiff + leftHeight}',
        '${leftOffset + width / 2},${leftDiff + leftHeight}',
        '${leftOffset + width / 2},$leftDiff'
      ];
      var label = svg.TextElement()
        ..setAttribute('x', (leftOffset + width / 2).toString())
        ..setAttribute('y', (leftDiff + leftHeight / 2 + 6).toString())
        ..setAttribute('font-size', '12px')
        ..setAttribute('visibility', 'hidden')
        ..innerHtml =
            '${chartConfig.data.last.label} (${chartConfig.data.last.value})';
      var funnel = svg.PolygonElement()
        ..setAttribute('points', points.join(' '))
        ..setAttribute('fill', chartConfig.colors[colorsIndex++])
        ..setAttribute('opacity', defaultOpacity)
        ..onMouseEnter.listen((event) {
          label.setAttribute('visibility', 'visible');
          (event.target as svg.PolygonElement)
              .setAttribute('opacity', hoverOpacity);
        })
        ..onMouseLeave.listen((event) {
          label.setAttribute('visibility', 'hidden');
          (event.target as svg.PolygonElement)
              .setAttribute('opacity', defaultOpacity);
        });
      svgWrapper.append(funnel);
      svgWrapper.append(label);
    }
  }

  colorsIndex = 0;
  var legendWrapper = html.DivElement();
  for (var i = 0; i < chartConfig.data.length - 1; i = i + increment) {
    var curr = chartConfig.data[i];
    var next = chartConfig.data[i + 1];
    var labelWrapper = html.SpanElement()..style.paddingRight = '24px';

    var label = html.SpanElement()
      ..innerText =
          chartConfig.isParied ? '${curr.label} → ${next.label}' : curr.label;
    var icon = html.SpanElement()
      ..style.backgroundColor = chartConfig.colors[colorsIndex++]
      ..style.marginRight = '4px'
      ..style.height = '12px'
      ..style.width = '12px'
      ..style.display = 'inline-block';
    labelWrapper.append(icon);
    labelWrapper.append(label);

    legendWrapper.append(labelWrapper);
  }

  if (chartConfig.isParied) {
    if (chartConfig.data.length.isOdd) {
      var labelWrapper = html.SpanElement()..style.paddingRight = '24px';
      var label = html.SpanElement()..innerText = chartConfig.data.last.label;
      var icon = html.SpanElement()
        ..style.backgroundColor = chartConfig.colors[colorsIndex++]
        ..style.marginRight = '4px'
        ..style.height = '12px'
        ..style.width = '12px'
        ..style.display = 'inline-block';
      labelWrapper.append(icon);
      labelWrapper.append(label);

      legendWrapper.append(labelWrapper);
    }
  }

  cardBody.append(svgWrapper);
  cardBody.append(legendWrapper);
  return wrapper;
}

void renderGeoMap(
    String title,
    String narrative,
    dynamic mapData,
    Map<String, List<num>> mapFilterValues,
    Map<String, List<num>> mapComparisonFilterValues,
    bool comparisonEnabled,
    bool normalisationEnabled,
    List<String> colors) {
  var mapID = uuid.v4();
  var mapPlaceholder =
      _generateGeoMapPlaceholder(mapID, title, narrative, comparisonEnabled);
  content.append(mapPlaceholder);

  var mapboxInstance = geomap_helpers.generateMapboxMap(mapID, mapData, false);
  mapboxInstance.on(
      'load',
      (_) => handleMapLoad(mapboxInstance, mapData, mapFilterValues,
          normalisationEnabled, colors[0]));

  if (comparisonEnabled) {
    var mapboxComparisonInstance =
        geomap_helpers.generateMapboxMap(mapID, mapData, true);
    mapboxComparisonInstance.on(
        'load',
        (_) => handleMapLoad(mapboxComparisonInstance, mapData,
            mapComparisonFilterValues, normalisationEnabled, colors[1]));
  }
}

void handleMapLoad(
    MapboxMap mapInstance,
    dynamic mapData,
    Map<String, List<num>> mapValues,
    bool normalisationEnabled,
    String fillColor) {
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

    var suffix = normalisationEnabled ? '%' : '';
    mapInstance.addLayer({
      'id': 'label-${regionID}',
      'type': 'symbol',
      'source': '${regionID}',
      'layout': {
        'text-field': '${regionName} (${mapValues[regionID][0]}${suffix})',
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

html.DivElement _generateChart(
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
    String id, String title, String narrative, bool comparisonEnabled) {
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

void renderSettingsConfigEditor(String config) {
  var wrapper = html.DivElement();
  content.append(wrapper);

  var textArea = html.TextAreaElement()..text = config;
  wrapper.append(textArea);

  var editor = code_mirror.CodeMirror.fromTextArea(textArea, options: {
    'mode': {'name': 'javascript', 'json': true},
    'lineNumbers': true
  });
  editor.setSize(null, 600);
  editor.focus();

  var alertElement = html.DivElement()
    ..classes = ['alert']
    ..id = CONFIG_SETTINGS_ALERT_ID
    ..hidden = true;
  wrapper.append(alertElement);

  var saveButton = html.ButtonElement()
    ..classes = ['btn', 'btn-primary']
    ..text = 'Update config'
    ..onClick.listen((e) {
      var data = editor.getDoc().getValue();
      command(UIAction.saveConfigToFirebase, SaveConfigToFirebaseData(data));
    });
  wrapper.append(saveButton);
}

void renderSettingsConfigUtility(Map<String, Set> uniqueValues) {
  var wrapper = html.DivElement()
    ..classes = [CONFIG_UNIQUE_VALUES_WRAPPER_CLASSNAME];
  content.append(wrapper);

  var skeletonHeader = html.HeadingElement.h5()
    ..text = 'Step 1: Skeleton of config';
  var skeletonCopyButton = html.ButtonElement()
    ..classes = ['btn', 'btn-outline-secondary']
    ..innerText = 'Copy config skeleton'
    ..onClick
        .listen((_) => command(UIAction.copyToClipboardConfigSkeleton, null));
  var skeletonInstructions = html.OListElement()..type = 'a';
  [
    'Fill <code>interactions</code> under data_paths',
    'Optionally fill <code>label</code> for each of the filters',
    'Fill <code>label</code> for each of the tabs',
    'Fill <code>exclude_filters: ["filter_key"]</code> for each of the tabs'
  ].forEach(
      (i) => skeletonInstructions.append(html.LIElement()..innerHtml = i));
  wrapper.append(skeletonHeader);
  wrapper.append(skeletonCopyButton);
  wrapper.append(skeletonInstructions);

  var chartConfigTitle = html.HeadingElement.h5()
    ..innerText = 'Step 2: Chart config / tabs > charts: []';
  var chartConfigInstructions = html.OListElement()..type = 'a';
  [
    'Optionally fill <code>label</code> for each of the field keys',
    'Optionally delete the unwanted fields from the chart config (esp. for themes)',
    'Optionally edit the chart type (defaults to bar)'
  ].forEach(
      (i) => chartConfigInstructions.append(html.LIElement()..innerHtml = i));
  var chartConfigTable = html.TableElement()
    ..classes = ['table', 'table-bordered'];
  uniqueValues.forEach((key, value) {
    var tableRow = html.TableRowElement();
    var fieldCol = html.TableCellElement()..innerText = key;
    var valuesCol = html.TableCellElement()
      ..innerText = (value.toList()..sort()).join(', ');
    var copyCol = html.TableCellElement();
    var copyButton = html.ButtonElement()
      ..classes = ['btn', 'btn-outline-secondary']
      ..innerText = 'Copy chart config'
      ..onClick.listen((_) => command(UIAction.copyToClipboardChartConfig,
          CopyToClipboardChartConfigData(key)));
    copyCol.append(copyButton);

    tableRow.append(fieldCol);
    tableRow.append(valuesCol);
    tableRow.append(copyCol);
    chartConfigTable.append(tableRow);
  });

  wrapper.append(chartConfigTitle);
  wrapper.append(chartConfigInstructions);
  wrapper.append(chartConfigTable);
}

void showConfigSettingsAlert(String message, bool isError) {
  configSettingsAlert
    ..text = message
    ..classes.toggle('alert-danger', isError)
    ..classes.toggle('alert-success', !isError)
    ..hidden = false;
}

void hideConfigSettingsAlert() {
  configSettingsAlert
    ..text = ''
    ..hidden = true;
}

void showAlert(String message) {
  html.window.alert('Error: ${message}');
}
