import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;
import 'utils.dart' as utils;
import 'package:chartjs/chartjs.dart';

DateTime _STARTDATE = DateTime(2020, 3, 13);

html.DivElement get genderChartWrapper => html.querySelector('#gender-chart');
html.DivElement get ageChartWrapper => html.querySelector('#age-chart');
html.DivElement get responseTypeChartWrapper =>
    html.querySelector('#response-type-chart');
html.DivElement get responseClassChartWrapper =>
    html.querySelector('#response-class-chart');
html.DivElement get responseThemesChartWrapper =>
    html.querySelector('#response-themes-chart');

html.CheckboxInputElement get normaliseChartCheckbox =>
    html.querySelector('#normalise-chart');
html.CheckboxInputElement get stackTrendCheckbox =>
    html.querySelector('#stack-trend');
html.SelectElement get chartTypeSelect => html.querySelector('#chart-type');

html.SpanElement get conversationCountWrapper =>
    html.querySelector('#messages-conversation');
html.SpanElement get messagesOutgoingWrapper =>
    html.querySelector('#messages-outgoing');
html.SpanElement get messagesIncomingNonDemogWrapper =>
    html.querySelector('#messages-incoming-non-demog');
html.SpanElement get messagesIncomingDemogWrapper =>
    html.querySelector('#messages-incoming-demog');
html.SpanElement get messagesTotalWrapper =>
    html.querySelector('#messages-total');

class App {
  List<model.DaySummary> _summaryMetrics;
  model.TopMetric _topMetric;
  bool _isNormalised = false;
  bool _isTrendStacked = false;
  String _chartType = 'line';
  bool _isFilled = false;

  App() {
    _init();
  }

  void _init() async {
    await fb.init();

    _summaryMetrics = await fb.readSummaryMetrics();
    _topMetric = await fb.readTopMetrics();
    _summaryMetrics
        .removeWhere((daySummary) => daySummary.date.isBefore(_STARTDATE));

    _renderTopMetrics();
    _renderCharts();
    normaliseChartCheckbox.onChange.listen(_handleNormaliseCharts);
    stackTrendCheckbox.onChange.listen(_handleStackCharts);
    chartTypeSelect.onChange.listen(_handleChartType);
  }

  void _renderTopMetrics() {
    conversationCountWrapper.text = utils.NumFormat(_topMetric.conversations);
    messagesOutgoingWrapper.text =
        utils.NumFormat(_topMetric.messages_outgoing);
    messagesIncomingDemogWrapper.text =
        utils.NumFormat(_topMetric.messages_incoming_demog);
    messagesIncomingNonDemogWrapper.text =
        utils.NumFormat(_topMetric.messages_incoming_non_demog);
    messagesTotalWrapper.text = utils.NumFormat(_topMetric.messages);
  }

  void _handleNormaliseCharts(_) {
    _isNormalised = normaliseChartCheckbox.checked;
    _chartType = 'line';
    _isTrendStacked = true;

    if (_isNormalised) {
      stackTrendCheckbox.disabled = true;
      chartTypeSelect.disabled = true;
    } else {
      stackTrendCheckbox.disabled = false;
      chartTypeSelect.disabled = false;
    }

    _renderCharts();
  }

  void _handleStackCharts(_) {
    _isTrendStacked = stackTrendCheckbox.checked;
    _renderCharts();
  }

  void _handleChartType(_) {
    _chartType = chartTypeSelect.value;
    _renderCharts();
  }

  void _renderCharts() {
    chartTypeSelect.value = _chartType;

    if (_isTrendStacked) {
      stackTrendCheckbox.setAttribute('checked', '');
    } else {
      stackTrendCheckbox.removeAttribute('checked');
    }

    if (_isNormalised) {
      normaliseChartCheckbox.setAttribute('checked', '');
    } else {
      normaliseChartCheckbox.removeAttribute('checked');
    }

    _isFilled = _chartType != 'line' || _isTrendStacked;

    _renderGenderChart();
    _renderAgeBucketChart();
    _renderResponseTypeChart();
    _renderClassificationChart();
    _renderThemesChart();
  }

  ChartOptions _generateChartOptions() {
    var labelString =
        _isNormalised ? 'Percentage of individuals' : 'Number of individuals';
    return ChartOptions(
        responsive: true,
        tooltips: ChartTooltipOptions(mode: 'index'),
        elements: ChartElementsOptions(line: ChartLineOptions(fill: -1)),
        legend: ChartLegendOptions(
            position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
        scales: ChartScales(display: true, xAxes: [
          ChartXAxe(stacked: _isTrendStacked)
        ], yAxes: [
          ChartYAxe(
              stacked: _isTrendStacked,
              scaleLabel:
                  ScaleTitleOptions(labelString: labelString, display: true))
        ]));
  }

  ChartDataSets getDataset(String key, bool isFirst, List data) {
    if (key == 'radio_show') {
      var onAirIcon = html.ImageElement(src: '/assets/onair.png', height: 16, width: 42);
      return ChartDataSets(
          label: utils.metadata[key].label,
          type: 'line',
          showLine: false,
          fill: '-1',
          pointRadius: 0,
          pointHoverRadius: 0,
          pointBorderWidth: 0,
          pointStyle: data.map((d) => d ? onAirIcon : null).toList(),
          data: data.map((d) => d ? 1 : 0).toList(),
          hideInLegendAndTooltip: true,
          backgroundColor: utils.metadata[key].color);
    }

    return ChartDataSets(
        label: utils.metadata[key].label,
        lineTension: 0,
        fill: _isFilled ? (isFirst ? 'origin' : '-1') : false,
        backgroundColor: utils.metadata[key].background,
        borderColor: utils.metadata[key].color,
        hoverBackgroundColor: utils.metadata[key].color,
        hoverBorderColor: utils.metadata[key].color,
        pointBackgroundColor: utils.metadata[key].color,
        pointRadius: 2,
        data: data);
  }

  void _renderGenderChart() {
    var dates = [], males = [], females = [], unknown = [], radioShow = [];
    for (var metric in _summaryMetrics) {
      var g = metric.gender;
      dates.add(utils.chartDateLabelFormat(metric.date));
      radioShow.add(metric.radioShow);

      if (_isNormalised) {
        var total = g.male + g.female + g.unknown;
        males.add(g.male / total * 100);
        females.add(g.female / total * 100);
        unknown.add(g.unknown / total * 100);
      } else {
        males.add(g.male);
        females.add(g.female);
        unknown.add(g.unknown);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      getDataset('radio_show', false, radioShow),
      getDataset('male', true, males),
      getDataset('female', false, females),
      getDataset('unknown', false, unknown)
    ]);

    var config = ChartConfiguration(
        type: _chartType, data: chartData, options: _generateChartOptions());

    genderChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    genderChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderAgeBucketChart() {
    var dates = [],
        bucket_0_18 = [],
        bucket_18_35 = [],
        bucket_35_50 = [],
        bucket_50_ = [],
        unknown = [],
        radioShow = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      radioShow.add(metric.radioShow);

      var a = metric.age;
      if (_isNormalised) {
        var total = a.bucket_0_18 +
            a.bucket_18_35 +
            a.bucket_35_50 +
            a.bucket_50_ +
            a.unknown;

        bucket_0_18.add(a.bucket_0_18 / total * 100);
        bucket_18_35.add(a.bucket_18_35 / total * 100);
        bucket_35_50.add(a.bucket_35_50 / total * 100);
        bucket_50_.add(a.bucket_50_ / total * 100);
        unknown.add(a.unknown / total * 100);
      } else {
        bucket_0_18.add(a.bucket_0_18);
        bucket_18_35.add(a.bucket_18_35);
        bucket_35_50.add(a.bucket_35_50);
        bucket_50_.add(a.bucket_50_);
        unknown.add(a.unknown);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      getDataset('radio_show', false, radioShow),
      getDataset('0_18', true, bucket_0_18),
      getDataset('18_35', false, bucket_18_35),
      getDataset('35_50', false, bucket_35_50),
      getDataset('50_', false, bucket_50_),
      getDataset('unknown', false, unknown)
    ]);

    var config = ChartConfiguration(
        type: _chartType, data: chartData, options: _generateChartOptions());

    ageChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    ageChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderResponseTypeChart() {
    var dates = [], escalate = [], answer = [], question = [], radioShow = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      radioShow.add(metric.radioShow);

      var t = metric.theme;
      if (_isNormalised) {
        var total = t.escalation + t.answer + t.question;
        escalate.add(t.escalation / total * 100);
        answer.add(t.answer / total * 100);
        question.add(t.question / total * 100);
      } else {
        escalate.add(t.escalation);
        answer.add(t.answer);
        question.add(t.question);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      getDataset('radio_show', false, radioShow),
      getDataset('escalate', true, escalate),
      getDataset('answer', false, answer),
      getDataset('question', false, question)
    ]);

    var config = ChartConfiguration(
        type: _chartType, data: chartData, options: _generateChartOptions());

    responseTypeChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    responseTypeChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderClassificationChart() {
    var dates = [],
        attitude = [],
        behaviour = [],
        knowledge = [],
        gratitude = [],
        radioShow = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      radioShow.add(metric.radioShow);

      var t = metric.theme;

      if (_isNormalised) {
        var total = t.attitude + t.behaviour + t.knowledge + t.gratitude;
        attitude.add(t.attitude / total * 100);
        behaviour.add(t.behaviour / total * 100);
        knowledge.add(t.knowledge / total * 100);
        gratitude.add(t.gratitude / total * 100);
      } else {
        attitude.add(t.attitude);
        behaviour.add(t.behaviour);
        knowledge.add(t.knowledge);
        gratitude.add(t.gratitude);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      getDataset('radio_show', false, radioShow),
      getDataset('attitude', true, attitude),
      getDataset('behaviour', false, behaviour),
      getDataset('knowledge', false, knowledge),
      getDataset('gratitude', false, gratitude)
    ]);

    var config = ChartConfiguration(
        type: _chartType, data: chartData, options: _generateChartOptions());

    responseClassChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    responseClassChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderThemesChart() {
    var dates = [],
        about_coronavirus = [],
        anxiety_panic = [],
        collective_hope = [],
        how_spread_transmitted = [],
        how_to_prevent = [],
        how_to_treat = [],
        opinion_on_govt_policy = [],
        other_theme = [],
        rumour_stigma_misinfo = [],
        symptoms = [],
        what_is_govt_policy = [],
        radioShow = [];

    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      radioShow.add(metric.radioShow);
      var t = metric.theme;

      if (_isNormalised) {
        var total = t.about_coronavirus +
            t.anxiety_panic +
            t.collective_hope +
            t.how_spread_transmitted +
            t.how_to_prevent +
            t.how_to_treat +
            t.opinion_on_govt_policy +
            t.other_theme +
            t.rumour_stigma_misinfo +
            t.symptoms +
            t.what_is_govt_policy;
        about_coronavirus.add(t.about_coronavirus / total * 100);
        anxiety_panic.add(t.anxiety_panic / total * 100);
        collective_hope.add(t.collective_hope / total * 100);
        how_spread_transmitted.add(t.how_spread_transmitted / total * 100);
        how_to_prevent.add(t.how_to_prevent / total * 100);
        how_to_treat.add(t.how_to_treat / total * 100);
        opinion_on_govt_policy.add(t.opinion_on_govt_policy / total * 100);
        other_theme.add(t.other_theme / total * 100);
        rumour_stigma_misinfo.add(t.rumour_stigma_misinfo / total * 100);
        symptoms.add(t.symptoms / total * 100);
        what_is_govt_policy.add(t.what_is_govt_policy / total * 100);
      } else {
        about_coronavirus.add(t.about_coronavirus);
        anxiety_panic.add(t.anxiety_panic);
        collective_hope.add(t.collective_hope);
        how_spread_transmitted.add(t.how_spread_transmitted);
        how_to_prevent.add(t.how_to_prevent);
        how_to_treat.add(t.how_to_treat);
        opinion_on_govt_policy.add(t.opinion_on_govt_policy);
        other_theme.add(t.other_theme);
        rumour_stigma_misinfo.add(t.rumour_stigma_misinfo);
        symptoms.add(t.symptoms);
        what_is_govt_policy.add(t.what_is_govt_policy);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      getDataset('radio_show', false, radioShow),
      getDataset('about_coronavirus', true, about_coronavirus),
      getDataset('anxiety_panic', false, anxiety_panic),
      getDataset('collective_hope', false, collective_hope),
      getDataset('how_spread_transmitted', false, how_spread_transmitted),
      getDataset('how_to_prevent', false, how_to_prevent),
      getDataset('how_to_treat', false, how_to_treat),
      getDataset('opinion_on_govt_policy', false, opinion_on_govt_policy),
      getDataset('rumour_stigma_misinfo', false, rumour_stigma_misinfo),
      getDataset('symptoms', false, symptoms),
      getDataset('what_is_govt_policy', false, what_is_govt_policy),
      getDataset('other_theme', false, other_theme)
    ]);

    var config = ChartConfiguration(
        type: _chartType, data: chartData, options: _generateChartOptions());

    responseThemesChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    responseThemesChartWrapper.append(canvas);
    Chart(canvas, config);
  }
}
