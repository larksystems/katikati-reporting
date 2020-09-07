import 'dart:js';
import 'dart:html' as html;
import 'package:chartjs/chartjs.dart' as chartjs;
import 'package:dashboard/extensions.dart';
import 'package:dashboard/chart_helpers.dart' as chart_helpers;
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class Chart {
  String id;
  html.DivElement container;
}

class UnimplementedChart extends Chart {
  UnimplementedChart() {
    id = uuid.v4();
    container = html.DivElement()..id = 'chart-${id}';
    container.innerText = 'Unimplemented chart';
  }

  void updateChartinView() {
    container.innerText = 'Unimplemented chart updated';
  }
}

class SummaryChart extends Chart {
  String title;
  List<String> labels;
  List<num> values;
  List<html.HeadingElement> displayValue;

  SummaryChart(this.title, this.labels, this.values) {
    id = uuid.v4();
    container = html.DivElement()..id = 'chart-${id}';
    displayValue = [];

    var card = html.DivElement()..classes = ['card'];
    var cardBody = html.DivElement()..classes = ['card-body'];

    var row = html.DivElement()..classes = ['row'];
    for (var i = 0; i < labels.length; ++i) {
      var column = html.DivElement()..classes = ['col-3'];
      var displayLabel = html.LabelElement()..innerText = labels[i];
      column.append(displayLabel);
      var formattedValue = formattedInt.format(values[i]);
      displayValue.add(html.HeadingElement.h1()..innerText = formattedValue);
      column.append(displayValue[i]);
      row.append(column);
    }

    cardBody.append(row);
    card.append(cardBody);
    container.append(card);
  }

  void updateChartInView() {
    for (var i = 0; i < displayValue.length; ++i) {
      displayValue[i].innerText = values[i].formatWithCommas();
    }
  }
}

class TimeSeriesLineChart extends Chart {
  chartjs.ChartData chartData;
  chartjs.Chart chart;
  html.CanvasElement canvas;

  String title;
  String dataCollection;
  String dataLabel;
  List<String> seriesNames;
  List<String> colors;
  Map<DateTime, List<num>> buckets;
  bool isNormalised = false;

  TimeSeriesLineChart(this.title, this.dataCollection, this.dataLabel,
      this.seriesNames, this.colors, this.buckets) {
    id = uuid.v4();
    colors = colors ?? chart_helpers.chartDefaultColors;
    container = html.DivElement()..id = 'chart-${id}';
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
          seriesNames[i], [], colors[i], false));
    }

    chartData = chartjs.ChartData(labels: [], datasets: chartDatasets);

    var tooltipLabelCallback =
        (chartjs.ChartTooltipItem tooltipItem, chartjs.ChartData data) {
      var xLabel = data.datasets[tooltipItem.datasetIndex].label;
      var yLabel = tooltipItem.yLabel;
      var suffix = isNormalised ? '%' : '';
      return '${xLabel}: ${yLabel}${suffix}';
    };

    var chartOptions = chartjs.ChartOptions(
        responsive: true,
        tooltips: chartjs.ChartTooltipOptions(
            mode: 'index',
            callbacks: chartjs.ChartTooltipCallback(
                label: allowInterop(tooltipLabelCallback))),
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
            ..scaleLabel =
                chartjs.ScaleTitleOptions(labelString: dataLabel, display: true)
            ..ticks = (chartjs.LinearTickOptions()..min = 0)
        ]),
        hover: chartjs.ChartHoverOptions()..animationDuration = 0);

    var chartConfig = chartjs.ChartConfiguration(
        type: 'line', data: chartData, options: chartOptions);
    chart = chartjs.Chart(canvas.getContext('2d'), chartConfig);
  }

  void updateChartinView(bool isNormalised, bool isStacked) {
    this.isNormalised = isNormalised;
    chart.data.labels = buckets.keys
        .map((date) => intl.DateFormat('dd MMM').format(date))
        .toList();

    var yScale = chart.options.scales.yAxes[0];
    yScale.stacked = isStacked;
    if (isNormalised) {
      yScale.ticks.max = 100;
    } else {
      var maxValue = 0;
      for (var bucket in buckets.values) {
        var sum = bucket.reduce((a, b) => a + b);
        if (maxValue < sum) maxValue = sum;
      }
      yScale.ticks.max = maxValue + 1000;
    }

    for (var i = 0; i < seriesNames.length; ++i) {
      chart.data.datasets[i].fill =
          isStacked ? (i == 0 ? 'origin' : '-1') : false;
      chart.data.datasets[i].data =
          buckets.values.map((value) => value[i]).toList();
    }

    chart.update(chartjs.ChartUpdateProps(duration: 0));
  }
}
