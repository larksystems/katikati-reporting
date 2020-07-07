import 'dart:math' as math;

extension RoundDecimals on num {
  num roundToDecimal(int fractionDigits) {
    var n = math.pow(10, fractionDigits);
    return (this * n).round() / n;
  }
}
