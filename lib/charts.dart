import 'dart:js';
import 'dart:html' as html;
import 'package:chartjs/chartjs.dart' as chartjs;
import 'package:dashboard/chart_helpers.dart' as chart_helpers;
import 'package:intl/intl.dart' as intl;
import 'package:dashboard/model.dart' as model;

class Chart {
  html.DivElement container;
}

class TimeSeriesLineChart extends Chart {
  chartjs.ChartData chartData;
  chartjs.Chart chart;
  html.CanvasElement canvas;

  String title;
  model.DataPath dataPath;
  String dataDoc; // todo: replace when data collections are generalised
  List<String> seriesNames;
  List<String> colors;
  Map<DateTime, List<num>> buckets;

  TimeSeriesLineChart(this.title, this.dataPath, this.dataDoc, this.seriesNames,
      this.colors, this.buckets) {
    colors = colors ?? chart_helpers.chartDefaultColors;
    container = html.DivElement();
    canvas = html.CanvasElement();

    var card = html.DivElement()..classes = ['card'];
    var cardBody = html.DivElement()..classes = ['card-body'];

    var heading = html.HeadingElement.h5()..innerText = title;
    container.append(heading);
    card.append(cardBody);
    cardBody.append(canvas);
    container.append(card);

    var chartDatasets = <chartjs.ChartDataSets>[];
    for (var i = 0; i < seriesNames.length; ++i) {
      chartDatasets.add(chart_helpers.generateTimeSeriesChartDataset(
          seriesNames[i], [1, 2, 3], colors[i], false));
    }

    chartData =
        chartjs.ChartData(labels: ['a', 'b', 'c'], datasets: chartDatasets);

    var chartOptions = chartjs.ChartOptions(
        responsive: true,
        tooltips: chartjs.ChartTooltipOptions(mode: 'index'),
        legend: chartjs.ChartLegendOptions(
            position: 'bottom',
            labels: chartjs.ChartLegendLabelOptions(boxWidth: 12)),
        scales: chartjs.LinearScale(xAxes: [
          chartjs.ChartXAxe()
            ..stacked = false
            ..ticks = (chartjs.LinearTickOptions()
              ..maxTicksLimit = 30
              ..autoSkip = true
              ..minRotation = 0
              ..maxRotation = 90)
        ], yAxes: [
          chartjs.ChartYAxe()
            ..stacked = false
            ..scaleLabel = chartjs.ScaleTitleOptions(
                labelString: 'Messages', display: true)
            ..ticks = (chartjs.LinearTickOptions()..min = 0)
        ]),
        hover: chartjs.ChartHoverOptions()..animationDuration = 0);

    var chartConfig = chartjs.ChartConfiguration(
        type: 'line', data: chartData, options: chartOptions);
    chart = chartjs.Chart(canvas.getContext('2d'), chartConfig);
  }

  void updateChart(bool isNormalised, bool isStacked) {
    chart.data.labels = buckets.keys
        .map((date) => intl.DateFormat('dd MMM').format(date))
        .toList();

    var tooltipLabelCallback =
        (chartjs.ChartTooltipItem tooltipItem, chartjs.ChartData data) {
      var xLabel = data.datasets[tooltipItem.datasetIndex].label;
      var yLabel = tooltipItem.yLabel;
      var suffix = isNormalised ? '%' : '';
      return '${xLabel}: ${yLabel}${suffix}';
    };

    var yScale = chart.options.scales.yAxes[0];
    yScale.stacked = isStacked;

    chart.options.tooltips = chartjs.ChartTooltipOptions(
        mode: 'index',
        callbacks: chartjs.ChartTooltipCallback(
            label: allowInterop(tooltipLabelCallback)));

    for (var i = 0; i < seriesNames.length; ++i) {
      chart.data.datasets[i].fill =
          isStacked ? (i == 0 ? 'origin' : '-1') : false;
      chart.data.datasets[i].data =
          buckets.values.map((value) => value[i]).toList();
    }

    chart.update(chartjs.ChartUpdateProps(duration: 0));
  }
}
