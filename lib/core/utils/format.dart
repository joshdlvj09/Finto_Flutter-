// Formato de montos y fechas en espanol (Mexico)
import 'package:intl/intl.dart';

class Format {
  Format._();

  // 1234.5 -> "$1,234.50" | 1000 -> "$1,000"
  static String money(double value) {
    final hasCents = (value * 100).round() % 100 != 0;
    final f = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: hasCents ? 2 : 0,
    );
    return f.format(value.abs());
  }

  // Version corta para las barras: 1500 -> "$1.5k"
  static String moneyShort(double value) {
    final abs = value.abs();
    String clean(double n) => n.toStringAsFixed(1).replaceAll('.0', '');
    if (abs >= 1000000) return '\$${clean(abs / 1000000)}M';
    if (abs >= 1000) return '\$${clean(abs / 1000)}k';
    return '\$${abs.round()}';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // "Hoy", "Ayer" o "lun 3 oct"
  static String dateLabel(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (isSameDay(date, today)) return 'Hoy';
    if (isSameDay(date, yesterday)) return 'Ayer';
    return DateFormat('EEE d MMM', 'es_MX').format(date);
  }

  static String fullDate(DateTime date) =>
      DateFormat("EEEE d 'de' MMMM yyyy, HH:mm", 'es_MX').format(date);
}
