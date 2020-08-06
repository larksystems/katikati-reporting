import 'dart:js';
import 'package:dashboard/model.dart' as model;
import 'package:chartjs/chartjs.dart';
import 'package:intl/intl.dart' as intl;

const barChartDefaultColors = ['#ef5350', '#07acc1'];
const lineChartDefaultColors = [
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

String _generateLegendLabelFromFilters(Map<String, String> filters) {
  var label = filters.values.join(',');
  return label != '' ? label : allInteractionsLabel;
}

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

ChartOptions _generateBarChartOptions(bool dataNormalisationEnabled) {
  var labelPrepend = dataNormalisationEnabled ? 'Percentage' : 'Number';
  var labelString = '${labelPrepend} of interactions';
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
    model.Chart chart,
    bool dataComparisonEnabled,
    bool dataNormalisationEnabled,
    Map<String, String> activeFilterValues,
    Map<String, String> activeComparisonFilterValues) {
  var labels = [];
  var filterData = List<num>();
  var comparisonFilterData = List<num>();

  // for (var chartCol in chart.fields) {
  //   labels.add(chartCol.label ?? chartCol.field.value);
  //   filterData.add(chartCol.bucket[0]);
  //   comparisonFilterData.add(chartCol.bucket[1]);
  // }

  var colors = chart.colors ?? barChartDefaultColors;

  var datasets = [
    _generateBarChartDataset(
        _generateLegendLabelFromFilters(activeFilterValues),
        filterData,
        colors[0]),
    if (dataComparisonEnabled)
      _generateBarChartDataset(
          _generateLegendLabelFromFilters(activeComparisonFilterValues),
          comparisonFilterData,
          colors[1])
  ];

  var dataset = ChartData(labels: labels, datasets: datasets);
  return ChartConfiguration(
      type: 'bar',
      data: dataset,
      options: _generateBarChartOptions(dataNormalisationEnabled));
}

ChartOptions _generateTimeSeriesChartOptions(
    bool dataNormalisationEnabled, bool stackTimeseriesEnabled) {
  var labelPrepend = dataNormalisationEnabled ? 'Percentage' : 'Number';
  var labelString = '${labelPrepend} of interactions';
  var chartX = ChartXAxe()
    ..stacked = false
    ..ticks = (LinearTickOptions()
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

ChartConfiguration generateTimeSeriesChartConfig(model.Chart chart,
    bool dataNormalisationEnabled, bool stackTimeseriesEnabled) {
  var colors = (chart.colors ?? [])..addAll(lineChartDefaultColors);
  return null;
  // var datasets = chart.fields.asMap().entries.map((entry) {
  //   var index = entry.key;
  //   var field = entry.value;
  //   return _generateTimeSeriesChartDataset(
  //       field.label ?? field.field,
  //       field.time_bucket.values.toList(),
  //       colors[index],
  //       stackTimeseriesEnabled ? (index == 0 ? 'origin' : '-1') : false);
  // }).toList();

  // return ChartConfiguration(
  //     type: 'line',
  //     data: ChartData(
  //         labels: chart.fields.first.time_bucket.keys.map((key) {
  //           var date = DateTime.parse(key);
  //           switch (chart.timestamp.aggregate) {
  //             case model.TimeAggregate.day:
  //               return intl.DateFormat('dd MMM').format(date);
  //             case model.TimeAggregate.hour:
  //             default:
  //               return intl.DateFormat('dd MMM h:mm a').format(date);
  //           }
  //         }).toList(),
  //         datasets: datasets),
  //     options: _generateTimeSeriesChartOptions(
  //         dataNormalisationEnabled, stackTimeseriesEnabled));
}
