import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;
import 'utils.dart' as utils;
import 'package:chartjs/chartjs.dart';

html.CanvasElement get genderChartCanvas => html.querySelector('#gender-chart');
html.CanvasElement get ageChartCanvas => html.querySelector('#age-chart');
html.CanvasElement get responseTypeChartCanvas =>
    html.querySelector('#response-type-chart');
html.CanvasElement get responseClassChartCanvas =>
    html.querySelector('#response-class-chart');

class App {
  List<model.DaySummary> _summaryMetrics;

  App() {
    _initFirebase();
  }

  void _initFirebase() async {
    await fb.init();
    _summaryMetrics = await fb.readSummaryMetrics();

    _renderGenderChart();
    _renderAgeBucketChart();
    _renderResponseTypeChart();
    _renderClassificationChart();
  }

  ChartOptions _generateChartOptions() {
    return ChartOptions(
        responsive: true,
        tooltips: ChartTooltipOptions(mode: 'index'),
        legend: ChartLegendOptions(
            position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
        scales: ChartScales(display: true, yAxes: [
          ChartYAxe(
              stacked: true,
              scaleLabel: ScaleTitleOptions(
                  labelString: 'Number of individuals', display: true))
        ]));
  }

  void _renderGenderChart() {
    var dates = [], males = [], females = [], unknown = [];
    for (var metric in _summaryMetrics) {
      dates.add(utils.chartDateLabelFormat(metric.date));
      males.add(metric.gender.male);
      females.add(metric.gender.female);
      unknown.add(metric.gender.unknown);
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      ChartDataSets(
          label: 'Male',
          lineTension: 0,
          fill: false,
          backgroundColor: 'purple',
          borderColor: 'purple',
          data: males),
      ChartDataSets(
          label: 'Female',
          lineTension: 0,
          fill: false,
          backgroundColor: 'red',
          borderColor: 'red',
          data: females),
      ChartDataSets(
          label: 'Unknown',
          lineTension: 0,
          fill: false,
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
      bucket_0_18.add(metric.age.bucket_0_18);
      bucket_18_35.add(metric.age.bucket_18_35);
      bucket_35_50.add(metric.age.bucket_35_50);
      bucket_50_.add(metric.age.bucket_50_);
      unknown.add(metric.age.unknown);
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      ChartDataSets(
          label: '0-18 Yrs',
          lineTension: 0,
          fill: false,
          backgroundColor: 'purple',
          borderColor: 'purple',
          data: bucket_0_18),
      ChartDataSets(
          label: '18-35 Yrs',
          lineTension: 0,
          fill: false,
          backgroundColor: 'red',
          borderColor: 'red',
          data: bucket_18_35),
      ChartDataSets(
          label: '35-50 Yrs',
          lineTension: 0,
          fill: false,
          backgroundColor: 'blue',
          borderColor: 'blue',
          data: bucket_35_50),
      ChartDataSets(
          label: '50+ Yrs',
          lineTension: 0,
          fill: false,
          backgroundColor: 'green',
          borderColor: 'green',
          data: bucket_50_),
      ChartDataSets(
          label: 'Unknown',
          lineTension: 0,
          fill: false,
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
      escalate.add(metric.theme.escalation);
      answer.add(metric.theme.attitude);
      question.add(metric.theme.question);
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      ChartDataSets(
          label: 'Escalate',
          lineTension: 0,
          fill: false,
          backgroundColor: 'red',
          borderColor: 'red',
          data: escalate),
      ChartDataSets(
          label: 'Answer',
          lineTension: 0,
          fill: false,
          backgroundColor: 'green',
          borderColor: 'green',
          data: answer),
      ChartDataSets(
          label: 'Question',
          lineTension: 0,
          fill: false,
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
      attitude.add(metric.theme.attitude);
      behaviour.add(metric.theme.behaviour);
      knowledge.add(metric.theme.knowledge);
    }

    var chartData = LinearChartData(labels: dates, datasets: <ChartDataSets>[
      ChartDataSets(
          label: 'Attitude',
          lineTension: 0,
          fill: false,
          backgroundColor: 'red',
          borderColor: 'red',
          data: attitude),
      ChartDataSets(
          label: 'Behaviour',
          lineTension: 0,
          fill: false,
          backgroundColor: 'orange',
          borderColor: 'orange',
          data: behaviour),
      ChartDataSets(
          label: 'Knowledge',
          lineTension: 0,
          fill: false,
          backgroundColor: 'green',
          borderColor: 'green',
          data: knowledge)
    ]);

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: _generateChartOptions());

    Chart(responseClassChartCanvas, config);
  }
}
