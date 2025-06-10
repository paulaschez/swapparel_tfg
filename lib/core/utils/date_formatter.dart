import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  static String formatListDate(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inHours < 24 && isSameDay(date, now)) {
      return timeago.format(
        date,
        locale: 'es',
      ); // "hace 5 minutos", "hace 2 horas"
    }

    if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    }

    if (difference.inDays < 7) {
      return DateFormat('E', 'es_ES').format(date); // "mar."
    }

    return DateFormat('dd/MM/yy').format(date); // "12/04/24"
  }

  static String formatMessageBubbleTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp.toDate()); // "14:20"
  }

  static String formatSeparatorDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'HOY';
    } else if (dateToCompare == yesterday) {
      return 'AYER';
    } else {
      return DateFormat.yMMMMd('es_ES').format(date);
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
