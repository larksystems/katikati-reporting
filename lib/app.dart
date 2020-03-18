import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;
import 'utils.dart' as utils;
import 'package:chartjs/chartjs.dart';

html.HeadingElement get topMetric1 => html.querySelector('#top_metric_1');
html.HeadingElement get topMetric2 => html.querySelector('#top_metric_2');
html.LabelElement get dateLabel => html.querySelector('#date');
html.CanvasElement get genderChartCanvas => html.querySelector('#gender-chart');

class App {
  List<model.DaySummary> _summaryMetrics;

  App() {
    _initFirebase();
  }

  void _initFirebase() async {
    await fb.init();
    _summaryMetrics = await fb.readSummaryMetrics();

    _renderTopMetrics();
    _renderGenderChart();
  }

  void _renderTopMetrics() {
    dateLabel.text = utils.chartDateLabelFormat(_summaryMetrics.last.date);
    topMetric1.text = utils.NumFormat(_summaryMetrics.last.top_metric_1);
    topMetric2.text = utils.NumFormat(_summaryMetrics.last.top_metric_2);
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

    var chartOptions = ChartOptions(
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

    var config = ChartConfiguration(
        type: 'line', data: chartData, options: chartOptions);

    Chart(genderChartCanvas, config);
  }
}
