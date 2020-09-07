import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;

var formattedInt = intl.NumberFormat('###,###', 'en_US');
var formattedDecimal = intl.NumberFormat('###,###.0#', 'en_US');

extension RoundDecimals on num {
  num get value => this;

  num roundToDecimal(int fractionDigits) {
    var n = math.pow(10, fractionDigits);
    return (this * n).round() / n;
  }

  String formatWithCommas() {
    var formattedValue = formattedInt.format(value);
    if (value.toInt() != value) {
      formattedValue = formattedDecimal.format(value);
    }
    return formattedValue;
  }
}
