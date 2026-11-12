// Calculos de periodos (semana / mes) para los resumenes de Finto.
// Es la misma logica que src/utils/periods.js de la version de Expo.
import 'package:intl/intl.dart';

import '../../data/models/movement.dart';
import '../constants/categories.dart';

enum PeriodMode { semana, mes }

class DateRange {
  final DateTime start;
  final DateTime end; // exclusivo
  const DateRange(this.start, this.end);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

class Totals {
  final double income;
  final double expenses;
  const Totals(this.income, this.expenses);
  double get balance => income - expenses;
}

class CategoryTotal {
  final MovementCategory category;
  final double amount;
  final double percent;
  const CategoryTotal(this.category, this.amount, this.percent);
}

class Bucket {
  final String label;
  final Totals totals;
  const Bucket(this.label, this.totals);
}

class Periods {
  Periods._();

  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  // offset 0 = periodo actual, -1 = anterior. Las semanas empiezan en lunes.
  static DateRange range(PeriodMode mode, int offset) {
    final now = DateTime.now();
    if (mode == PeriodMode.semana) {
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final start = DateTime(monday.year, monday.month, monday.day + offset * 7);
      return DateRange(start, DateTime(start.year, start.month, start.day + 7));
    }
    return DateRange(
      DateTime(now.year, now.month + offset, 1),
      DateTime(now.year, now.month + offset + 1, 1),
    );
  }

  static String label(PeriodMode mode, int offset, DateRange r) {
    if (mode == PeriodMode.semana) {
      if (offset == 0) return 'Esta semana';
      if (offset == -1) return 'Semana pasada';
      final last = r.end.subtract(const Duration(days: 1));
      final f = DateFormat('d MMM', 'es_MX');
      return '${f.format(r.start)} – ${f.format(last)}';
    }
    final text = DateFormat('MMMM yyyy', 'es_MX').format(r.start);
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<Movement> filter(List<Movement> list, DateRange r) =>
      list.where((m) => r.contains(m.date)).toList();

  static Totals totals(List<Movement> list) {
    double income = 0, expenses = 0;
    for (final m in list) {
      if (m.isIncome) {
        income += m.amount;
      } else {
        expenses += m.amount;
      }
    }
    return Totals(income, expenses);
  }

  // Suma por categoria, de mayor a menor, con porcentaje
  static List<CategoryTotal> byCategory(List<Movement> list, String type) {
    final map = <String, double>{};
    for (final m in list.where((m) => m.type == type)) {
      map[m.category] = (map[m.category] ?? 0) + m.amount;
    }
    final sum = map.values.fold<double>(0, (a, b) => a + b);
    final result = map.entries
        .map((e) => CategoryTotal(
              Categories.byId(e.key),
              e.value,
              sum > 0 ? e.value / sum * 100 : 0,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  // Barras: por dia en modo semana, por semana (S1..S5) en modo mes
  static List<Bucket> buckets(List<Movement> list, PeriodMode mode, DateRange r) {
    final buckets = <Bucket>[];
    if (mode == PeriodMode.semana) {
      for (var i = 0; i < 7; i++) {
        final s = DateTime(r.start.year, r.start.month, r.start.day + i);
        final e = DateTime(s.year, s.month, s.day + 1);
        buckets.add(Bucket(_dayNames[i], totals(filter(list, DateRange(s, e)))));
      }
    } else {
      var day = 1, index = 1;
      while (true) {
        final s = DateTime(r.start.year, r.start.month, day);
        if (!s.isBefore(r.end)) break;
        var e = DateTime(r.start.year, r.start.month, day + 7);
        if (e.isAfter(r.end)) e = r.end;
        buckets.add(Bucket('S$index', totals(filter(list, DateRange(s, e)))));
        day += 7;
        index++;
      }
    }
    return buckets;
  }
}
