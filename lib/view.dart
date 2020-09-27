import 'package:dashboard/model.dart' as model;
import 'dart:html' as html;
import 'dart:svg' as svg;
import 'package:uuid/uuid.dart';
import 'controller.dart';
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
String _generateFilterOptionID(String dataPath, String key) =>
    'filter-dropdown-${dataPath}_${key}';
String _generateFilterCheckboxID(String key) => 'filter-option-${key}';
String _generateAnalyseTabID(String key) => 'analyse-tab-options-${key}';

class AnalyseTabsViews {
  html.DivElement _wrapper;
  html.DivElement _content;

  AnalyseTabsViews(List<String> tabLabels, int selected) {
    _wrapper = html.DivElement()..classes = ['row', 'filter-row'];

    var labelCol = html.DivElement()..classes = ['col-2'];
    var label = html.LabelElement()..innerText = 'Analyse';
    labelCol.append(label);

    _content = html.DivElement()..classes = ['col-10'];
    for (var i = 0; i < tabLabels.length; ++i) {
      var radioWrapper = html.DivElement()
        ..classes = ['form-check', 'form-check-inline'];
      var radioOption = html.InputElement()
        ..type = 'radio'
        ..id = _generateAnalyseTabID(i.toString())
        ..name = 'analyse-tab-options'
        ..classes = ['form-check-input']
        ..checked = i == selected
        ..onChange.listen((e) {
          if (!(e.target as html.RadioButtonInputElement).checked) return;
          command(UIAction.changeAnalysisTab, AnalysisTabChangeData(i));
        });
      var radioLabel = html.LabelElement()
        ..htmlFor = _generateAnalyseTabID(i.toString())
        ..classes = ['form-check-label']
        ..innerText = tabLabels[i];

      radioWrapper.append(radioOption);
      radioWrapper.append(radioLabel);
      _content.append(radioWrapper);
    }

    _wrapper.append(labelCol);
    _wrapper.append(_content);
    content.append(_wrapper);
  }
}

class ChartOptionsView {
  html.DivElement _wrapper;
  html.DivElement _content;

  ChartOptionsView(bool compareData, bool normaliseData, bool stackTimeseries) {
    _wrapper = html.DivElement()..classes = ['row', 'filter-row'];

    var labelCol = html.DivElement()..classes = ['col-2'];
    var label = html.LabelElement()..innerText = 'Options';
    labelCol.append(label);

    _content = html.DivElement()..classes = ['col-10'];
    var comparisonCheckbox = _getCheckboxWithLabel(
        'comparison-option', 'Compare data', compareData, (bool checked) {
      command(UIAction.toggleDataComparison, ToggleOptionEnabledData(checked));
    });
    _content.append(comparisonCheckbox);

    var normalisationCheckbox = _getCheckboxWithLabel(
        'normalisation-option', 'Normalise data', normaliseData,
        (bool checked) {
      command(
          UIAction.toggleDataNormalisation, ToggleOptionEnabledData(checked));
    });
    _content.append(normalisationCheckbox);

    var stackTimeseriesCheckbox = _getCheckboxWithLabel(
        'stack-timeseries',
        'Stack time series',
        stackTimeseries,
        (bool checked) => command(
            UIAction.toggleStackTimeseries, ToggleOptionEnabledData(checked)));
    _content.append(stackTimeseriesCheckbox);

    _wrapper.append(labelCol);
    _wrapper.append(_content);
    content.append(_wrapper);
  }
}

class DataFiltersView {
  html.DivElement _wrapper;
  html.DivElement _content;

  DataFiltersView() {
    _wrapper = html.DivElement()..classes = ['row', 'filter-row', 'last'];

    var labelCol = html.DivElement()..classes = ['col-2'];
    var label = html.LabelElement()..innerText = 'Filters';
    labelCol.append(label);

    _content = html.DivElement()..classes = ['col-10'];

    _wrapper.append(labelCol);
    _wrapper.append(_content);
    content.append(_wrapper);
  }

  void update(List<model.FilterValue> filters, bool comparisonEnabled) {
    _content.children.clear();

    for (var i = 0; i < filters.length; ++i) {
      var filter = filters[i];
      var filterRow = generateGridRowElement(
          id: _generateFilterRowID(filter.dataCollection + filter.key));
      var checkboxCol = html.DivElement()..classes = ['col-4'];
      var filterCol = html.DivElement()..classes = ['col-3'];
      var comparisonFilterCol = html.DivElement()..classes = ['col-3'];

      var checkboxWithLabel = _getCheckboxWithLabel(
          _generateFilterCheckboxID(filter.dataCollection + filter.key),
          filter.dataCollection + ' / ' + filter.key,
          filter.isActive, (bool checked) {
        command(
            UIAction.toggleActiveFilter, ToggleActiveFilterData(i, checked));
      });

      switch (filter.type) {
        case model.DataType.datetime:
          var options = filter.options.isEmpty
              ? ['1970-01-01', DateTime.now().toIso8601String()]
              : filter.options;
          var startDateChooser = html.InputElement()
            ..disabled = !filter.isActive
            ..id = _generateFilterOptionID(filter.dataCollection, filter.key)
            ..type = 'date'
            ..min = options.first.split('T').first
            ..max = options.last.split('T').first
            ..value = filter.value.split('_').first
            ..onChange.listen((event) {
              var newValue =
                  '${(event.target as html.InputElement).value}_${filter.value.split('_').last}';
              command(UIAction.setFilterValue, SetFilterValueData(i, newValue));
            });
          var endDateChooser = html.InputElement()
            ..disabled = !filter.isActive
            ..id = _generateFilterOptionID(filter.dataCollection, filter.key)
            ..type = 'date'
            ..min = options.first.split('T').first
            ..max = options.last.split('T').first
            ..value = filter.value.split('_').last
            ..onChange.listen((event) {
              var newValue =
                  '${filter.value.split('_').first}_${(event.target as html.InputElement).value}';
              command(UIAction.setFilterValue, SetFilterValueData(i, newValue));
            });
          filterCol.append(startDateChooser);
          filterCol.append(endDateChooser);
          break;
        case model.DataType.string:
          var filterDropdown = _getDropdown(
              _generateFilterOptionID(filter.dataCollection, filter.key),
              filter.options,
              filter.value,
              !filter.isActive, (String value) {
            command(UIAction.setFilterValue, SetFilterValueData(i, value));
          });
          var comparisonFilterDropdown = _getDropdown(
              _generateFilterOptionID(filter.dataCollection, filter.key),
              filter.options,
              filter.comparisonValue,
              !filter.isActive, (String value) {
            command(UIAction.setComparisonFilterValue,
                SetFilterValueData(i, value));
          });
          filterCol.append(filterDropdown);
          if (comparisonEnabled) {
            comparisonFilterCol.append(comparisonFilterDropdown);
          }
          break;
      }

      checkboxCol.append(checkboxWithLabel);
      filterRow.append(checkboxCol);
      filterRow.append(filterCol);
      filterRow.append(comparisonFilterCol);
      _content.append(filterRow);
    }
  }
}

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
    ..onClick.listen((_) {
      command(UIAction.changeNavTab, NavChangeData(pathname));
      html.window.location.hash = pathname;
    });
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

void enableFilterOptions(String dataPath, String filterKey) {
  var id = _generateFilterOptionID(dataPath, filterKey);
  var options = html.querySelectorAll('#${id}');
  options.forEach((e) {
    if (e is html.InputElement) e.disabled = false;
    if (e is html.SelectElement) e.disabled = false;
  });
}

void disableFilterOptions(String dataPath, String filterKey) {
  var id = _generateFilterOptionID(dataPath, filterKey);
  var options = html.querySelectorAll('#${id}');
  options.forEach((e) {
    if (e is html.InputElement) e.disabled = true;
    if (e is html.SelectElement) e.disabled = true;
  });
}

void renderChart(
    String title, String narrative, chartjs.ChartConfiguration chartConfig) {
  var chart = _generateChart(title, narrative, chartConfig);
  content.append(chart);
}

void renderFunnelChart(String title, String narrative, List<String> colors,
    List<String> stages, List<num> values, bool isPaired) {
  var chart =
      _generateFunnelChart(title, narrative, colors, stages, values, isPaired);
  content.append(chart);
}

html.DivElement _generateFunnelChart(String title, String narrative,
    List<String> colors, List<String> stages, List<num> values, bool isPaired) {
  var wrapper = html.DivElement()..classes = [CHART_WRAPPER_CLASSNAME];

  var titleElement = html.HeadingElement.h5()..text = title;
  var narrativeElement = html.ParagraphElement()..text = narrative;
  wrapper.append(titleElement);
  wrapper.append(narrativeElement);

  var card = html.DivElement()..classes = [CARD_CLASSNAME];
  var cardBody = html.DivElement()..classes = [CARD_BODY_CLASSNAME];
  card.append(cardBody);
  wrapper.append(card);

  var maxDataValue = values.first;
  var chartHeight = 360;
  var maxHeight = 300;
  var width = 96;
  var xOffset = 30;
  var yOffset = 30;
  var increment = isPaired ? 2 : 1;
  var colorsIndex = 0;
  var defaultOpacity = '0.8';
  var hoverOpacity = '1.0';

  var svgWrapper = svg.SvgSvgElement()
    ..setAttribute('width', '100%')
    ..setAttribute('height', chartHeight.toString());

  for (var i = 0; i < values.length - 1; i = i + increment) {
    var curr = values[i];
    var next = values[i + 1];

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
      ..innerHtml = '${stages[i]} (${values[i]})';
    var bottomLabel = svg.TextElement()
      ..setAttribute('x', x3.toString())
      ..setAttribute('y', (y3 + 12).toString())
      ..setAttribute('font-size', '12px')
      ..setAttribute('visibility', 'hidden')
      ..innerHtml = '${stages[i + 1]} (${values[i + 1]})';

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
      ..setAttribute('fill', colors[colorsIndex++])
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

  if (isPaired) {
    if (values.length.isOdd) {
      var leftHeight = values.last / maxDataValue * maxHeight;
      var leftDiff = (maxHeight - leftHeight) / 2 + yOffset;
      var leftOffset = xOffset + ((values.length - 1) / 2) * width;
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
        ..innerHtml = '${stages.last} (${values.last})';
      var funnel = svg.PolygonElement()
        ..setAttribute('points', points.join(' '))
        ..setAttribute('fill', colors[colorsIndex++])
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
  for (var i = 0; i < values.length - 1; i = i + increment) {
    var labelWrapper = html.SpanElement()..style.paddingRight = '24px';

    var label = html.SpanElement()
      ..innerText = isPaired ? '${stages[i]} → ${stages[i + 1]}' : stages[i];
    var icon = html.SpanElement()
      ..style.backgroundColor = colors[colorsIndex++]
      ..style.marginRight = '4px'
      ..style.height = '12px'
      ..style.width = '12px'
      ..style.display = 'inline-block';
    labelWrapper.append(icon);
    labelWrapper.append(label);

    legendWrapper.append(labelWrapper);
  }

  if (isPaired) {
    if (values.length.isOdd) {
      var labelWrapper = html.SpanElement()..style.paddingRight = '24px';
      var label = html.SpanElement()..innerText = stages.last;
      var icon = html.SpanElement()
        ..style.backgroundColor = colors[colorsIndex++]
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

void appendCharts(List<html.DivElement> containers) {
  for (var container in containers) {
    content.append(container);
  }
}

void removeChart(String id) {
  var chartToRemove = content.querySelector('#chart-${id}');
  if (chartToRemove != null) {
    chartToRemove.remove();
  } else {
    logger.error('Chart to remove ${id} not found');
  }
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
