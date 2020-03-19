import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;
import 'utils.dart' as utils;
import 'package:chartjs/chartjs.dart';

DateTime _STARTDATE = DateTime(2020, 3, 13);

html.CanvasElement get genderChartCanvas => html.querySelector('#gender-chart');
html.CanvasElement get ageChartCanvas => html.querySelector('#age-chart');
html.CanvasElement get responseTypeChartCanvas =>
    html.querySelector('#response-type-chart');
html.CanvasElement get responseClassChartCanvas =>
    html.querySelector('#response-class-chart');

html.CheckboxInputElement get normaliseChartCheckbox =>
    html.querySelector('#normalise-chart');

class App {
  List<model.DaySummary> _summaryMetrics;
  bool _isNormalised = false;

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
  }

  void _handleNormaliseCharts(_) {
    _isNormalised = normaliseChartCheckbox.checked;
    _renderCharts();
  }

  void _renderCharts() {
    _renderGenderChart();
    _renderAgeBucketChart();
    _renderResponseTypeChart();
    _renderClassificationChart();
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
              stacked: true,
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

    Chart(genderChartCanvas, config);
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

    Chart(ageChartCanvas, config);
  }

  void _renderResponseTypeChart() {
    var dates = [], escalate = [], answer = [], question = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      var t = metric.theme;

      if (_isNormalised) {
        var total = t.escalation + t.attitude + t.question;
        escalate.add(t.escalation / total * 100);
        answer.add(t.attitude / total * 100);
        question.add(t.question / total * 100);
      } else {
        escalate.add(t.escalation);
        answer.add(t.attitude);
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

    Chart(responseTypeChartCanvas, config);
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

    Chart(responseClassChartCanvas, config);
  }
}
