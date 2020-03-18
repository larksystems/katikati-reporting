import 'package:intl/intl.dart';

String chartDateLabelFormat(DateTime time) {
  return DateFormat.MMMd().format(time);
}

String NumFormat(int num) {
  return NumberFormat().format(num);
}
