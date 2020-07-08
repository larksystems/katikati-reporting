import 'dart:js';
import 'package:dashboard/model.dart' as model;
import 'package:chartjs/chartjs.dart';

const barChartDefaultColors = ['#ef5350', '#07acc1'];
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
      backgroundColor: barColor + 'aa',
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
    ..barPercentage = 1;

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

  for (var chartCol in chart.fields) {
    labels.add(chartCol.label ?? chartCol.field.value);
    filterData.add(chartCol.bucket[0]);
    comparisonFilterData.add(chartCol.bucket[1]);
  }

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
