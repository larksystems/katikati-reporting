import 'dart:js';
import 'package:dashboard/model.dart' as model;
import 'package:chartjs/chartjs.dart';
import 'package:intl/intl.dart' as intl;

const chartDefaultColors = [
  '#3366cc',
  '#dc3912',
  '#ff9900',
  '#109618',
  '#990099',
  '#0099c6',
  '#dd4477',
  '#66aa00',
  '#b82e2e',
  '#316395',
  '#994499',
  '#22aa99',
  '#aaaa11',
  '#6633cc',
  '#e67300',
  '#8b0707',
  '#651067',
  '#329262',
  '#5574a6',
  '#3b3eac',
  '#b77322',
  '#16d620',
  '#b91383',
  '#f4359e',
  '#9c5935',
  '#a9c413',
  '#2a778d',
  '#668d1c',
  '#bea413',
  '#0c5922',
  '#743411'
];
const allInteractionsLabel = 'All interactions';

ChartDataSets _generateBarChartDataset(
    String label, List<num> data, String barColor) {
  return ChartDataSets(
      label: label,
      fill: true,
      backgroundColor: '${barColor}aa',
      borderColor: barColor,
      hoverBackgroundColor: barColor,
      hoverBorderColor: barColor,
      borderWidth: 1,
      data: data);
}

ChartOptions _generateBarChartOptions(
    bool dataNormalisationEnabled, String dataLabel) {
  var labelPrepend = dataNormalisationEnabled ? 'Percentage' : 'Number';
  var labelString = '${labelPrepend} of ${dataLabel}';
  var chartX = ChartXAxe()
    ..stacked = false
    ..barPercentage = 1
    ..ticks = (LinearTickOptions()
      ..autoSkip = false
      ..minRotation = 0
      ..maxRotation = 90);

  var chartY = ChartYAxe()
    ..stacked = false
    ..scaleLabel = ScaleTitleOptions(labelString: labelString, display: true)
    ..ticks = (LinearTickOptions()..min = 0);

  var tooltipLabelCallback = (ChartTooltipItem tooltipItem, ChartData data) {
    var xLabel = data.datasets[tooltipItem.datasetIndex].label;
    var yLabel = tooltipItem.yLabel;
    var suffix = dataNormalisationEnabled ? '%' : '';
    return '${xLabel}: ${yLabel}${suffix}';
  };

  return ChartOptions(
      responsive: true,
      tooltips: ChartTooltipOptions(
          mode: 'index',
          callbacks:
              ChartTooltipCallback(label: allowInterop(tooltipLabelCallback))),
      legend: ChartLegendOptions(
          position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
      scales: ChartScales(display: true, xAxes: [chartX], yAxes: [chartY]));
}

ChartConfiguration generateBarChartConfig(
    model.ComputedBarChart chart,
    bool dataComparisonEnabled,
    bool dataNormalisationEnabled,
    String seriesLabel,
    String comparisonSeriesLabel) {
  var labels = chart.labels;
  var filterData = chart.buckets.map((bucket) => bucket.first).toList();
  var comparisonFilterData =
      chart.buckets.map((bucket) => bucket.last).toList();

  var colors = chart.colors ?? chartDefaultColors;

  var datasets = [
    _generateBarChartDataset(seriesLabel, filterData, colors[0]),
    if (dataComparisonEnabled)
      _generateBarChartDataset(
          comparisonSeriesLabel, comparisonFilterData, colors[1])
  ];

  var dataset = ChartData(labels: labels, datasets: datasets);
  return ChartConfiguration(
      type: 'bar',
      data: dataset,
      options:
          _generateBarChartOptions(dataNormalisationEnabled, chart.dataLabel));
}

ChartOptions _generateTimeSeriesChartOptions(bool dataNormalisationEnabled,
    bool stackTimeseriesEnabled, String dataLabel) {
  var labelPrepend = dataNormalisationEnabled ? 'Percentage' : 'Number';
  var labelString = '${labelPrepend} of ${dataLabel}';
  var chartX = ChartXAxe()
    ..stacked = false
    ..ticks = (LinearTickOptions()
      ..maxTicksLimit = 30
      ..autoSkip = true
      ..minRotation = 0
      ..maxRotation = 90);

  var chartY = ChartYAxe()
    ..stacked = stackTimeseriesEnabled
    ..scaleLabel = ScaleTitleOptions(labelString: labelString, display: true)
    ..ticks = (LinearTickOptions()..min = 0);
  if (dataNormalisationEnabled) {
    chartY.ticks.max = 100;
  }

  var tooltipLabelCallback = (ChartTooltipItem tooltipItem, ChartData data) {
    var xLabel = data.datasets[tooltipItem.datasetIndex].label;
    var yLabel = tooltipItem.yLabel;
    var suffix = dataNormalisationEnabled ? '%' : '';
    return '${xLabel}: ${yLabel}${suffix}';
  };

  return ChartOptions(
      responsive: true,
      tooltips: ChartTooltipOptions(
          mode: 'index',
          callbacks:
              ChartTooltipCallback(label: allowInterop(tooltipLabelCallback))),
      legend: ChartLegendOptions(
          position: 'bottom', labels: ChartLegendLabelOptions(boxWidth: 12)),
      scales: ChartScales(display: true, xAxes: [chartX], yAxes: [chartY]));
}

ChartDataSets _generateTimeSeriesChartDataset(
    String label, List<num> data, String lineColor, dynamic filled) {
  return ChartDataSets(
      label: label,
      fill: filled,
      backgroundColor: '${lineColor}aa',
      borderColor: lineColor,
      hoverBackgroundColor: lineColor,
      hoverBorderColor: lineColor,
      pointHoverBackgroundColor: lineColor,
      pointRadius: 2,
      borderWidth: 1,
      lineTension: 0,
      data: data);
}

ChartConfiguration generateTimeSeriesChartConfig(
    model.ComputedTimeSeriesChart chart,
    bool dataNormalisationEnabled,
    bool stackTimeseriesEnabled) {
  var colors = (chart.colors ?? [])..addAll(chartDefaultColors);

  var datasets = chart.seriesLabels.asMap().entries.map((e) {
    var index = e.key;
    var seriesLabel = e.value;
    var seriesData = chart.buckets.values.map((valueList) {
      return valueList[index];
    }).toList();
    return _generateTimeSeriesChartDataset(
        seriesLabel,
        seriesData,
        colors[index],
        stackTimeseriesEnabled ? (index == 0 ? 'origin' : '-1') : false);
  }).toList();

  return ChartConfiguration(
      type: 'line',
      data: ChartData(
          labels: chart.buckets.keys
              .map((date) => intl.DateFormat('dd MMM').format(date))
              .toList(),
          datasets: datasets),
      options: _generateTimeSeriesChartOptions(
          dataNormalisationEnabled, stackTimeseriesEnabled, chart.dataLabel));
}
