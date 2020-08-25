import 'dart:html' as html;
import 'package:chartjs/chartjs.dart' as chartjs;
import 'package:dashboard/chart_helpers.dart' as chart_helpers;
import 'package:intl/intl.dart' as intl;
import 'package:dashboard/model.dart' as model;

class Chart {
  html.DivElement container;
}

class TimeSeriesLineChart extends Chart {
  chartjs.ChartData data;
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

    var heading = html.HeadingElement.h5();
    container.append(heading);
    card.append(cardBody);
    cardBody.append(canvas);
    container.append(card);

    var chartDatasets = <chartjs.ChartDataSets>[];
    for (var i = 0; i < seriesNames.length; ++i) {
      chartDatasets.add(chartjs.ChartDataSets(
          label: seriesNames[i], borderColor: colors[i], data: []));
    }

    data = chartjs.ChartData(labels: [], datasets: chartDatasets);

    var chartOptions = chartjs.ChartOptions(
        legend: chartjs.ChartLegendOptions(display: false),
        scales: chartjs.LinearScale(xAxes: [
          chartjs.ChartXAxe()
        ], yAxes: [
          chartjs.ChartYAxe()
            ..ticks = (chartjs.LinearTickOptions()..beginAtZero = true)
        ]),
        hover: chartjs.ChartHoverOptions()..animationDuration = 0);

    var chartConfig = chartjs.ChartConfiguration(
        type: 'line', data: data, options: chartOptions);
    chart = chartjs.Chart(canvas.getContext('2d'), chartConfig);
  }

  void updateChart(bool isNormalised, bool isStacked) {
    var labels = buckets.keys
        .map((date) => intl.DateFormat('dd MMM').format(date))
        .toList();
    var datasets = seriesNames.asMap().entries.map((e) {
      var index = e.key;
      var seriesLabel = e.value;
      var seriesData = buckets.values.map((valueList) {
        return valueList[index];
      }).toList();
      return chart_helpers.generateTimeSeriesChartDataset(
          seriesLabel, seriesData, colors[index], false);
    }).toList();

    data = chartjs.ChartData(labels: labels, datasets: datasets);
    chart.data = data;
    chart.update(chartjs.ChartUpdateProps(duration: 0));
  }
}
