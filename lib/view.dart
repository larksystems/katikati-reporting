import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:svg' as svg;
import 'model.dart' as model;
import 'utils.dart' as util;
import 'package:covid/map.dart' as _map;
import 'package:covid/controller.dart';
import 'package:chartjs/chartjs.dart';

List<html.Element> get _navLinks => html.querySelectorAll('.nav-item');
List<html.DivElement> get _contents => html.querySelectorAll('.content');

html.DivElement get loadingModal => html.querySelector('#loading-modal');
html.DivElement get loginModal => html.querySelector('#login-modal');
html.ButtonElement get loginButton => html.querySelector('#login-button');
html.DivElement get loginError => html.querySelector('#login-error');

html.DivElement get timelineWrapper => html.querySelector('#messages-timeline');
html.SelectElement get messagesSort =>
    html.querySelector('#messages-sort-select');

List<html.RadioButtonInputElement> get analyseChooser =>
    html.querySelectorAll('.analyse-radio');
html.CheckboxInputElement get enableCompare =>
    html.querySelector('#interactions-compare');
html.CheckboxInputElement get enableNormalise =>
    html.querySelector('#interactions-normalise');
html.DivElement get analyseThemeContent =>
    html.querySelector('#analyse-themes-content');
html.DivElement get analyseDemogContent =>
    html.querySelector('#analyse-demographics-content');
html.DivElement get analyseThemesFilterWrapper =>
    html.querySelector('#analyse-themes-filter-wrapper');
html.DivElement get analyseDemogFilterWrapper =>
    html.querySelector('#analyse-demographics-filter-wrapper');
html.DivElement get analyseDemogCompareWrapper =>
    html.querySelector('#analyse-demographics-compare-wrapper');

html.DivElement get responseClassificationGraphWrapper =>
    html.querySelector('#analyse-themes-response-classification-graph');
html.DivElement get responseThemeGraphWrapper =>
    html.querySelector('#analyse-themes-response-theme-graph');

html.DivElement get demogGenderGraphWrapper =>
    html.querySelector('#analyse-demographics-gender-graph');
html.DivElement get demogAgeGraphWrapper =>
    html.querySelector('#analyse-demographics-age-graph');
html.DivElement get demogIDPWrapper =>
    html.querySelector('#analyse-demographics-idp-graph');
html.DivElement get demogLangWrapper =>
    html.querySelector('#analyse-demographics-language-graph');

html.DivElement get demogMapWrapper =>
    html.querySelector('#analyse-demographics-map');
html.DivElement get demogMapCompareWrapper =>
    html.querySelector('#analyse-demographics-map-compare');

class View {
  Controller controller;

  View() {
    _listenToNavbarChanges();
    _listenToMessagesSort();

    _listenToEnableCompare();
    _listenToEnableNormalise();
    _listenToAnalyseChooser();
  }

  void _listenToNavbarChanges() {
    _navLinks.forEach((link) {
      link.onClick.listen((_) {
        controller.chooseNavTab(link.getAttribute('id'));
      });
    });
  }

  void _listenToMessagesSort() {
    messagesSort.onChange.listen((e) {
      var value = (e.currentTarget as html.SelectElement).value;
      switch (value) {
        case 'desc':
          controller.sortMisinfoMessages();
          break;
        case 'asc':
          controller.sortMisinfoMessages(desc: false);
          break;
        default:
          logger.error('No such sort option');
      }
      controller.renderMisinfoMessages();
    });
  }

  void _listenToEnableCompare() {
    enableCompare.onChange.listen((e) {
      var enabled = (e.target as html.CheckboxInputElement).checked;
      controller.enableCompare(enabled);
    });
  }

  void _listenToEnableNormalise() {
    enableNormalise.onChange.listen((e) {
      var enabled = (e.target as html.CheckboxInputElement).checked;
      controller.enableNormalise(enabled);
    });
  }

  void _listenToAnalyseChooser() {
    analyseChooser.forEach((chooser) {
      chooser.onChange.listen((e) {
        var value = (e.currentTarget as html.RadioButtonInputElement).value;
        switch (value) {
          case 'themes':
            controller.setInteractionTab('theme');
            break;
          case 'demographics':
            controller.setInteractionTab('demog');
            break;
          default:
            logger.error('No such analyse option');
        }
      });
    });
  }

  void _updateNavbar() {
    _navLinks.forEach((link) {
      var id = link.getAttribute('id');
      if (id == controller.visibleTabID) {
        link.classes.toggle('active', true);
      } else {
        link.classes.remove('active');
      }
    });
  }

  void _updateContent() {
    _contents.forEach((content) {
      var id = content.getAttribute('data-tab');
      if (id == controller.visibleTabID) {
        content.attributes.remove('hidden');
      } else {
        content.attributes.addAll({'hidden': 'true'});
      }
    });
  }

  void showLoginModal() {
    loginModal.removeAttribute('hidden');
  }

  void hideLoginModal() {
    loginModal.setAttribute('hidden', 'true');
  }

  void showLoginError(String errorMessage) {
    loginError
      ..removeAttribute('hidden')
      ..innerText = errorMessage;
  }

  void hideLoginError() {
    loginError.setAttribute('hidden', 'true');
  }

  void showLoading() {
    loadingModal.removeAttribute('hidden');
  }

  void hideLoading() {
    loadingModal.setAttribute('hidden', 'true');
  }

  // Messages sort & timeline
  html.DivElement _getMessageRow(model.Message message) {
    var row = html.DivElement()..classes = ['row'];
    var colLeft = html.DivElement()
      ..classes = ['col-lg-2', 'col-md-6', 'col-6', 'timeline-col'];
    var colRight = html.DivElement()
      ..classes = ['col-lg-6', 'col-md-6', 'col-6'];

    var messageBox = html.DivElement()..classes = ['message-box'];

    var messageText = html.DivElement()..innerText = message.text;
    messageBox.append(messageText);

    if (message.translation != null) {
      var translatedText = html.DivElement()
        ..classes = ['message-translated']
        ..innerText = message.translation;
      messageBox.append(translatedText);
    }

    colRight.append(messageBox);

    var timeBox = html.DivElement()
      ..classes = ['message-time']
      ..innerText = util.messageTimeFormat(message.received_at);
    colLeft.append(timeBox);

    return row..append(colLeft)..append(colRight);
  }

  void setMessagesSortSelect(bool desc) {
    messagesSort.value = desc ? 'desc' : 'asc';
  }

  void renderMessagesTimeline(List<model.Message> messages) {
    timelineWrapper.children.clear();

    var displayMessages = List<model.Message>.from(messages);
    displayMessages.forEach((m) => {timelineWrapper.append(_getMessageRow(m))});
  }

  // Interaction methods
  void toggleInteractionTab(String tabID) {
    switch (tabID) {
      case 'theme':
        analyseThemeContent.removeAttribute('hidden');
        analyseDemogContent.setAttribute('hidden', 'true');
        break;
      case 'demog':
        analyseDemogContent.removeAttribute('hidden');
        analyseThemeContent.setAttribute('hidden', 'true');
        break;
      default:
        logger.error('No such interaction tab to show');
    }
  }

  html.DivElement _getThemeFilterRow(
      model.InteractionFilter filter,
      Map<String, String> filterValues,
      Map<String, String> filterCompareValues,
      List<String> activeFilters,
      bool isCompareEnabled) {
    var row = html.DivElement()..classes = ['row'];
    var checkboxCol = html.DivElement()..classes = ['col-3'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];
    var compareCol = html.DivElement()..classes = ['col-2'];

    var label = html.LabelElement()
      ..text = filter.label
      ..htmlFor = filter.value;
    var checkbox = html.CheckboxInputElement()
      ..setAttribute('id', filter.value)
      ..onChange.listen((e) {
        if ((e.target as html.CheckboxInputElement).checked) {
          controller.addToActiveFilters(filter.value);
        } else {
          controller.removeFromActiveFilters(filter.value);
        }
      });
    checkboxCol..append(checkbox)..append(label);

    var dropdown = html.SelectElement()
      ..classes = ['form-control']
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.setFilterValue(filter.value, value);
      });

    var compare = html.SelectElement()
      ..classes = ['form-control']
      ..setAttribute('value', 'all')
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.setFilterCompareValue(filter.value, value);
      });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == filterValues[filter.value]) {
        option.setAttribute('selected', 'true');
      } else if (filterValues[filter.value] == null && o.value == 'all') {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == filterCompareValues[filter.value]) {
        option.setAttribute('selected', 'true');
      } else if (filterCompareValues[filter.value] == null &&
          o.value == 'all') {
        option.setAttribute('selected', 'true');
      }
      compare.append(option);
    });

    dropdownCol.append(dropdown);
    compareCol.append(compare);

    if (activeFilters.contains(filter.value)) {
      checkbox.setAttribute('checked', 'true');
      dropdown.removeAttribute('disabled');

      if (isCompareEnabled) {
        compare.removeAttribute('disabled');
      }
    }

    row..append(checkboxCol)..append(dropdownCol)..append(compareCol);
    return row;
  }

  html.SpanElement _getFilterABLabel(String id) {
    var wrapper = html.SpanElement();
    var box = html.SpanElement()
      ..innerText = '▣ '
      ..style.color = util.metadata[id].color;
    var label = html.SpanElement()..innerText = util.metadata[id].label;
    return wrapper..append(box)..append(label);
  }

  void renderInteractionThemeFilters(
      List<model.InteractionFilter> filters,
      Map<String, String> filterValues,
      Map<String, String> filterCompareValues,
      List<String> activeFilters,
      bool isCompareEnabled) {
    analyseThemesFilterWrapper.children.clear();

    var row = html.DivElement();
    row
      ..classes = ['row']
      ..append(html.DivElement()..classes = ['col-3'])
      ..append(html.DivElement()
        ..classes = ['col-2']
        ..append(_getFilterABLabel('a')))
      ..append(html.DivElement()
        ..classes = ['col-2']
        ..append(_getFilterABLabel('b')));
    analyseThemesFilterWrapper.append(row);

    filters.forEach((f) {
      analyseThemesFilterWrapper.append(_getThemeFilterRow(f, filterValues,
          filterCompareValues, activeFilters, isCompareEnabled));
    });
  }

  html.DivElement _getDemogFilterRow(model.InteractionFilter filter,
      Map<String, String> filterValues, List<String> activeFilters) {
    var row = html.DivElement()..classes = ['row'];
    var checkboxCol = html.DivElement()..classes = ['col-3'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];

    var label = html.LabelElement()
      ..text = filter.label
      ..htmlFor = 'demog_' + filter.value;
    var checkbox = html.CheckboxInputElement()
      ..setAttribute('id', 'demog_' + filter.value)
      ..onChange.listen((e) {
        if ((e.target as html.CheckboxInputElement).checked) {
          controller.addToActiveFilters(filter.value);
        } else {
          controller.removeFromActiveFilters(filter.value);
        }
      });
    checkboxCol..append(checkbox)..append(label);

    var dropdown = html.SelectElement()
      ..setAttribute('disabled', 'true')
      ..classes = ['form-control']
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.setFilterValue(filter.value, value);
        controller.setFilterCompareValue(filter.value, value);
      });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == filterValues[filter.value]) {
        option.setAttribute('selected', 'true');
      } else if (filterValues[filter.value] == null && o.value == 'all') {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });
    dropdownCol.append(dropdown);

    if (activeFilters.contains(filter.value)) {
      dropdown.removeAttribute('disabled');
      checkbox.setAttribute('checked', 'true');
    }

    row..append(checkboxCol)..append(dropdownCol);
    return row;
  }

  void renderInteractionDemogFilters(List<model.InteractionFilter> filters,
      Map<String, String> filterValues, List<String> activeFilters) {
    analyseDemogFilterWrapper.children.clear();

    filters.forEach((f) {
      analyseDemogFilterWrapper
          .append(_getDemogFilterRow(f, filterValues, activeFilters));
    });
  }

  void renderInteractionDemogThemes(List<model.Option> themes,
      bool isCompareEnabled, String theme, String compareTheme) {
    analyseDemogCompareWrapper.children.clear();

    var row = html.DivElement()..classes = ['row'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];
    var compareCol = html.DivElement()..classes = ['col-2'];

    var dropdown = html.SelectElement()
      ..classes = ['form-control']
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.setFilterValue('theme', value);
      });

    themes.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (theme == o.value) {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });

    var compare = html.SelectElement()
      ..classes = ['form-control']
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.setFilterCompareValue('theme', value);
      });

    themes.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == compareTheme) {
        option.setAttribute('selected', 'true');
      }
      compare.append(option);
    });

    if (isCompareEnabled) {
      compare.removeAttribute('disabled');
    }

    dropdownCol.append(dropdown);
    compareCol.append(compare);

    row..append(dropdownCol)..append(compareCol);

    analyseDemogCompareWrapper.append(row);
  }

  ChartOptions _generateChartOptions({bool isNormaliseEnabled = false}) {
    var labelString =
        (isNormaliseEnabled ? 'Percentage' : 'Number') + ' of interactions';
    var chartY = ChartYAxe(
        stacked: false,
        scaleLabel: ScaleTitleOptions(labelString: labelString, display: true));
    chartY.ticks = TickOptions(min: 0);
    if (isNormaliseEnabled) {
      chartY.ticks = TickOptions(max: 100, min: 0);
    }

    return ChartOptions(
        responsive: true,
        animation: ChartAnimationOptions(duration: 0),
        tooltips: ChartTooltipOptions(mode: 'index'),
        legend: ChartLegendOptions(
            position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
        scales: ChartScales(
            display: true,
            xAxes: [ChartXAxe(stacked: false)],
            yAxes: [chartY]));
  }

  ChartDataSets _getDataset(String key, List data, {String forceColor}) {
    var metadata = util.metadata[key];
    if (!util.metadata.containsKey(key)) {
      metadata = util.MetaData(forceColor ?? '#000000', key);
    }

    if (forceColor != null) {
      metadata.color = forceColor;
    }

    return ChartDataSets(
        label: metadata.label,
        lineTension: 0,
        fill: true,
        backgroundColor: metadata.background,
        borderColor: metadata.color,
        hoverBackgroundColor: metadata.color,
        hoverBorderColor: metadata.color,
        pointBackgroundColor: metadata.color,
        pointRadius: 2,
        borderWidth: 1,
        data: data);
  }

  void _renderThemeChart(
      List<String> themeIDs,
      List<model.Interaction> interactions,
      List<model.Interaction> compareInteractions,
      html.DivElement wrapper,
      bool isCompareEnabled,
      bool isNormaliseEnabled) {
    var buckets = {
      for (var t in themeIDs..sort((a, b) => a.compareTo(b)))
        t: model.Bucket(0, 0)
    };

    for (var interaction in interactions) {
      interaction.themes
          .forEach((t) => buckets[t] != null ? ++buckets[t].count : null);
    }

    for (var interaction in compareInteractions) {
      interaction.themes
          .forEach((t) => buckets[t] != null ? ++buckets[t].compare : null);
    }

    List<num> aDataset = [];
    List<num> bDataset = [];

    buckets.forEach((_, value) {
      aDataset.add(value.count);
      bDataset.add(value.compare);
    });

    if (isNormaliseEnabled) {
      aDataset = _getNormalisedPercent(aDataset, interactions.length);
      bDataset = _getNormalisedPercent(bDataset, compareInteractions.length);
    }

    var dataSets = <ChartDataSets>[_getDataset('a', aDataset)];
    if (isCompareEnabled) {
      dataSets.add(_getDataset('b', bDataset));
    }

    var chartData = LinearChartData(
        labels: buckets.keys.map((k) {
          return util.metadata[k] == null ? k : util.metadata[k].label;
        }).toList(),
        datasets: dataSets);

    var config = ChartConfiguration(
        type: 'bar',
        data: chartData,
        options: _generateChartOptions(isNormaliseEnabled: isNormaliseEnabled));

    wrapper.children.clear();
    var canvas = html.CanvasElement();
    wrapper.append(canvas);
    Chart(canvas, config);
  }

  void renderThemeGraphs(
      List<model.Interaction> interactions,
      List<model.Interaction> compareInteractions,
      bool isCompareEnabled,
      bool isNormaliseEnabled,
      List<String> themeIDs) {
    logger.log('Rendering graphs for themes');

    var classThemesIDs = [
      'attitude',
      'behaviour',
      'knowledge',
      'statement',
      'question'
    ];
    _renderThemeChart(
        classThemesIDs,
        interactions,
        compareInteractions,
        responseClassificationGraphWrapper,
        isCompareEnabled,
        isNormaliseEnabled);

    var filteredThemeIDs = List<String>.from(themeIDs);
    for (var theme in classThemesIDs) {
      filteredThemeIDs.remove(theme);
    }
    filteredThemeIDs.remove('all');

    _renderThemeChart(
      filteredThemeIDs,
      interactions,
      compareInteractions,
      responseThemeGraphWrapper,
      isCompareEnabled,
      isNormaliseEnabled,
    );
  }

  void _renderDemogGenderGraph(
      String type,
      List<model.Interaction> interactions,
      List<model.Interaction> compareInteractions,
      html.DivElement wrapper,
      bool isCompareEnabled,
      bool isNormaliseEnabled,
      List<model.InteractionFilter> filters,
      Map<String, String> filterValues,
      Map<String, String> filterCompareValues) {
    var filter = filters.firstWhere((f) => f.value == type);
    var buckets = {};
    for (var f in filter.options..sort((a, b) => a.label.compareTo(b.label))) {
      if (f.value != 'all') {
        buckets[f.value] = model.Bucket(0, 0);
      }
    }

    for (var interaction in interactions) {
      switch (type) {
        case 'gender':
          ++buckets[interaction.gender].count;
          break;
        case 'age':
          ++buckets[interaction.age_bucket].count;
          break;
        case 'idp_status':
          ++buckets[interaction.idp_status].count;
          break;
        case 'household_language':
          ++buckets[interaction.household_language].count;
          break;
        default:
          logger.error('No such interaction to count');
      }
    }

    for (var interaction in compareInteractions) {
      switch (type) {
        case 'gender':
          ++buckets[interaction.gender].compare;
          break;
        case 'age':
          ++buckets[interaction.age_bucket].compare;
          break;
        case 'idp_status':
          ++buckets[interaction.idp_status].compare;
          break;
        case 'household_language':
          ++buckets[interaction.household_language].compare;
          break;
        default:
          logger.error('No such interaction to count');
      }
    }

    List<num> aDataset = [];
    List<num> bDataset = [];

    buckets.forEach((_, value) {
      aDataset.add(value.count);
      bDataset.add(value.compare);
    });

    if (isNormaliseEnabled) {
      aDataset = _getNormalisedPercent(aDataset, interactions.length);
      bDataset = _getNormalisedPercent(bDataset, compareInteractions.length);
    }

    var dataSets = <ChartDataSets>[
      _getDataset(filterValues['theme'], aDataset,
          forceColor: util.metadata['a'].color)
    ];
    if (isCompareEnabled) {
      dataSets.add(_getDataset(filterCompareValues['theme'], bDataset,
          forceColor: util.metadata['b'].color));
    }

    var chartData = LinearChartData(
        labels: buckets.keys.map((k) {
          return util.metadata[k] == null ? k : util.metadata[k].label;
        }).toList(),
        datasets: dataSets);

    var config = ChartConfiguration(
        type: 'bar',
        data: chartData,
        options: _generateChartOptions(isNormaliseEnabled: isNormaliseEnabled));

    wrapper.children.clear();
    var canvas = html.CanvasElement();
    wrapper.append(canvas);
    Chart(canvas, config);
  }

  void renderDemogGraphs(
      List<model.Interaction> interactions,
      List<model.Interaction> compareInteractions,
      bool isCompareEnabled,
      bool isNormaliseEnabled,
      List<model.InteractionFilter> filters,
      Map<String, String> filterValues,
      Map<String, String> filterCompareValues) {
    logger.log('Rendering graphs for demographics');

    _renderDemogGenderGraph(
        'gender',
        interactions,
        compareInteractions,
        demogGenderGraphWrapper,
        isCompareEnabled,
        isNormaliseEnabled,
        filters,
        filterValues,
        filterCompareValues);
    _renderDemogGenderGraph(
        'age',
        interactions,
        compareInteractions,
        demogAgeGraphWrapper,
        isCompareEnabled,
        isNormaliseEnabled,
        filters,
        filterValues,
        filterCompareValues);
    _renderDemogGenderGraph(
        'idp_status',
        interactions,
        compareInteractions,
        demogIDPWrapper,
        isCompareEnabled,
        isNormaliseEnabled,
        filters,
        filterValues,
        filterCompareValues);
    _renderDemogGenderGraph(
        'household_language',
        interactions,
        compareInteractions,
        demogLangWrapper,
        isCompareEnabled,
        isNormaliseEnabled,
        filters,
        filterValues,
        filterCompareValues);
    _renderDemogMap(interactions, compareInteractions, isCompareEnabled,
        isNormaliseEnabled, filters, filterValues, filterCompareValues);
  }

  svg.SvgSvgElement _getSomaliaMap(Map<String, num> buckets, num max,
      String color, bool isNormaliseEnabled) {
    var img = svg.SvgSvgElement()
      ..setAttribute('viewBox', _map.somalia['viewbox'])
      ..setAttribute('style', 'enable-background: ${_map.somalia["viewbox"]}');

    var regionsGroup = svg.GElement()..setAttribute('id', 'regions');
    var labelsGroup = svg.GElement()..setAttribute('id', 'labels');

    (_map.somalia['regions'] as Map<String, dynamic>).forEach((k, region) {
      var regionPath = svg.PathElement()
        ..classes = ['map-region']
        ..setAttribute('fill', color)
        ..setAttribute('stroke', color)
        ..setAttribute('d', region['path'])
        ..setAttribute('fill-opacity', (buckets[k] / max).toString());
      regionsGroup.append(regionPath);

      var text = svg.TextElement()
        ..classes = ['map-label']
        ..setAttribute('transform', 'matrix(1 0 0 1 ${region["label-pos"]})')
        ..appendText(region['name'] +
            '(' +
            buckets[k].toString() +
            (isNormaliseEnabled ? '%' : '') +
            ')');

      if (region['line'] != null) {
        var pts = region['line'].toString().split(',');
        var line = svg.LineElement()
          ..classes = ['map-line']
          ..setAttribute('x1', pts[0])
          ..setAttribute('y1', pts[1])
          ..setAttribute('x2', pts[2])
          ..setAttribute('y2', pts[3]);
        labelsGroup.append(line);
      }

      labelsGroup.append(text);
    });

    return img..append(regionsGroup)..append(labelsGroup);
  }

  void _renderDemogMap(
      List<model.Interaction> interactions,
      List<model.Interaction> compareInteractions,
      bool isCompareEnabled,
      bool isNormalisedEnabled,
      List<model.InteractionFilter> filters,
      Map<String, String> filterValues,
      Map<String, String> filterCompareValues) async {
    demogMapWrapper.children.clear();
    demogMapCompareWrapper.children.clear();
    var filter = filters.firstWhere((f) => f.value == 'location_region');

    var buckets = {for (var t in filter.options) t.value: model.Bucket(0, 0)};
    for (var interaction in interactions) {
      ++buckets[interaction.location_region].count;
    }

    var counts = buckets.map((k, v) {
      var value = isNormalisedEnabled
          ? util.trucateDecimal(v.count / interactions.length * 100, 2)
          : v.count;
      return MapEntry(k, value);
    });

    var mapToShow = _getSomaliaMap(counts, counts.values.reduce(math.max),
        util.metadata['a'].color, isNormalisedEnabled);
    demogMapWrapper.append(mapToShow);

    if (!isCompareEnabled) return;

    for (var interaction in compareInteractions) {
      ++buckets[interaction.location_region].compare;
    }

    var compareCounts = buckets.map((k, v) {
      var value = isNormalisedEnabled
          ? util.trucateDecimal(v.compare / compareInteractions.length * 100, 2)
          : v.compare;
      return MapEntry(k, value);
    });

    var compMapToShow = _getSomaliaMap(
        compareCounts,
        compareCounts.values.reduce(math.max),
        util.metadata['b'].color,
        isNormalisedEnabled);
    demogMapCompareWrapper.append(compMapToShow);
  }

  List<num> _getNormalisedPercent(List<num> values, int count) {
    return values
        .map((value) => util.trucateDecimal((value / count) * 100, 2))
        .toList();
  }

  void render() {
    _updateNavbar();
    _updateContent();
  }
}
