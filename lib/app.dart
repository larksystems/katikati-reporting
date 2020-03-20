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

class App {
  List<model.DaySummary> _summaryMetrics;
  bool _isNormalised = false;
  bool _isTrendStacked = false;

  App() {
    _init();
  }

  void _init() async {
    await fb.init();

    _summaryMetrics = await fb.readSummaryMetrics();
    _summaryMetrics
        .removeWhere((daySummary) => daySummary.date.isBefore(_STARTDATE));

    _renderCharts();
    normaliseChartCheckbox.onChange.listen(_handleNormaliseCharts);
    stackTrendCheckbox.onChange.listen(_handleStackCharts);
  }

  void _handleNormaliseCharts(_) {
    _isNormalised = normaliseChartCheckbox.checked;
    _renderCharts();
  }

  void _handleStackCharts(_) {
    _isTrendStacked = stackTrendCheckbox.checked;
    _renderCharts();
  }

  void _renderCharts() {
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
        legend: ChartLegendOptions(
            position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
        scales: ChartScales(display: true, yAxes: [
          ChartYAxe(
              stacked: _isTrendStacked,
              scaleLabel:
                  ScaleTitleOptions(labelString: labelString, display: true))
        ]));
  }

  void _renderGenderChart() {
    var dates = [], males = [], females = [], unknown = [];
    for (var metric in _summaryMetrics) {
      var g = metric.gender;
      dates.add(utils.chartDateLabelFormat(metric.date));

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
      ChartDataSets(
          label: 'Male',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'purple',
          borderColor: 'purple',
          data: males),
      ChartDataSets(
          label: 'Female',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'red',
          borderColor: 'red',
          data: females),
      ChartDataSets(
          label: 'Unknown',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'silver',
          borderColor: 'silver',
          data: unknown)
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

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
        unknown = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));

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
      ChartDataSets(
          label: '0-18 Yrs',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'purple',
          borderColor: 'purple',
          data: bucket_0_18),
      ChartDataSets(
          label: '18-35 Yrs',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'red',
          borderColor: 'red',
          data: bucket_18_35),
      ChartDataSets(
          label: '35-50 Yrs',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'blue',
          borderColor: 'blue',
          data: bucket_35_50),
      ChartDataSets(
          label: '50+ Yrs',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'green',
          borderColor: 'green',
          data: bucket_50_),
      ChartDataSets(
          label: 'Unknown',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'silver',
          borderColor: 'silver',
          data: unknown),
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

    ageChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    ageChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderResponseTypeChart() {
    var dates = [], escalate = [], answer = [], question = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
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
      ChartDataSets(
          label: 'Escalate',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'red',
          borderColor: 'red',
          data: escalate),
      ChartDataSets(
          label: 'Answer',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'green',
          borderColor: 'green',
          data: answer),
      ChartDataSets(
          label: 'Question',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: 'orange',
          borderColor: 'orange',
          data: question)
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

    responseTypeChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    responseTypeChartWrapper.append(canvas);
    Chart(canvas, config);
  }

  void _renderClassificationChart() {
    var dates = [], attitude = [], behaviour = [], knowledge = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      var t = metric.theme;

      if (_isNormalised) {
        var total = t.attitude + t.behaviour + t.knowledge;
        attitude.add(t.attitude / total * 100);
        behaviour.add(t.behaviour / total * 100);
        knowledge.add(t.knowledge / total * 100);
      } else {
        attitude.add(t.attitude);
        behaviour.add(t.behaviour);
        knowledge.add(t.knowledge);
      }
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      ChartDataSets(
          label: 'Attitude',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#ab47bc',
          borderColor: '#ab47bc',
          data: attitude),
      ChartDataSets(
          label: 'Behaviour',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#42a5f5',
          borderColor: '#42a5f5',
          data: behaviour),
      ChartDataSets(
          label: 'Knowledge',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#26a69a',
          borderColor: '#26a69a',
          data: knowledge)
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

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
        gratitude = [],
        how_spread_transmitted = [],
        how_to_prevent = [],
        how_to_treat = [],
        opinion_on_govt_policy = [],
        other_theme = [],
        rumour_stigma_misinfo = [],
        symptoms = [],
        what_is_govt_policy = [];

    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      var t = metric.theme;

      if (_isNormalised) {
        var total = t.about_coronavirus +
            t.anxiety_panic +
            t.collective_hope +
            t.gratitude +
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
        gratitude.add(t.gratitude / total * 100);
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
        gratitude.add(t.gratitude);
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
      ChartDataSets(
          label: 'About corona virus',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#78909c',
          borderColor: '#78909c',
          data: about_coronavirus),
      ChartDataSets(
          label: 'Anxiety or panic',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#ff7043',
          borderColor: '#ff7043',
          data: anxiety_panic),
      ChartDataSets(
          label: 'Collective hope',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#9ccc65',
          borderColor: '#9ccc65',
          data: collective_hope),
      ChartDataSets(
          label: 'gratitude',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#66bb6a',
          borderColor: '#66bb6a',
          data: gratitude),
      ChartDataSets(
          label: 'How virus spreads / transmitted',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#26c6da',
          borderColor: '#26c6da',
          data: how_spread_transmitted),
      ChartDataSets(
          label: 'How to prevent',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#29b6f6',
          borderColor: '#29b6f6',
          data: how_to_prevent),
      ChartDataSets(
          label: 'How to treat',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#26a69a',
          borderColor: '#26a69a',
          data: how_to_treat),
      ChartDataSets(
          label: 'Opinion on govt. policy',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#5c6bc0',
          borderColor: '#5c6bc0',
          data: opinion_on_govt_policy),
      ChartDataSets(
          label: 'Other themes',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#bdbdbd',
          borderColor: '#bdbdbd',
          data: other_theme),
      ChartDataSets(
          label: 'Rumour, stigma, or misinfo',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#d32f2f',
          borderColor: '#d32f2f',
          data: rumour_stigma_misinfo),
      ChartDataSets(
          label: 'Symptoms',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#f06292',
          borderColor: '#f06292',
          data: symptoms),
      ChartDataSets(
          label: 'What is govt. policy',
          lineTension: 0,
          fill: _isNormalised,
          backgroundColor: '#ab47bc',
          borderColor: '#ab47bc',
          data: what_is_govt_policy),
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

    responseThemesChartWrapper.children.clear();
    var canvas = html.CanvasElement();
    responseThemesChartWrapper.append(canvas);
    Chart(canvas, config);
  }
}
