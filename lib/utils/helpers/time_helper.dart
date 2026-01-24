
import 'package:intl/intl.dart';

class TimeHelper {
  static String formatMatchTime(DateTime date) {
    return DateFormat('HH:mm').format(date.toLocal());
  }

  static String formatMessageTime(DateTime date) {
    return DateFormat('HH:mm').format(date.toLocal());
  }
}
