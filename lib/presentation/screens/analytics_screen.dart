// Analisis: resumen semanal o mensual con graficas de barras y dona
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../core/utils/periods.dart';
import '../providers/movement_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  PeriodMode _mode = PeriodMode.semana;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<MovementProvider>().movements;

    final range = Periods.range(_mode, _offset);
    final list = Periods.filter(all, range);
    final totals = Periods.totals(list);
    final previous = Periods.totals(Periods.filter(all, Periods.range(_mode, _offset - 1)));
    final buckets = Periods.buckets(list, _mode, range);
    final byCategory = Periods.byCategory(list, 'gasto');

    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      drawer: const AppDrawer(currentRoute: AppRoutes.analytics),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<PeriodMode>(
            segments: const [
              ButtonSegment(value: PeriodMode.semana, label: Text('Semana')),
              ButtonSegment(value: PeriodMode.mes, label: Text('Mes')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _offset = 0;
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _offset--),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  Periods.label(_mode, _offset, range),
                  key: ValueKey('$_mode$_offset'),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance del periodo', style: TextStyle(color: AppColors.secondary)),
                  Text(
                    '${totals.balance < 0 ? '-' : ''}${Format.money(totals.balance)}',
                    style: TextStyle(
                      color: totals.balance < 0 ? AppColors.expense : AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _comparison(totals.expenses, previous.expenses),
                  const SizedBox(height: 16),
                  IncomeExpenseBarChart(buckets: buckets),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _legend(AppColors.chartIncome, 'Ingresos ${Format.money(totals.income)}'),
                      const SizedBox(width: 16),
                      _legend(AppColors.chartExpense, 'Gastos ${Format.money(totals.expenses)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Gastos por categoría', style: TextStyle(color: AppColors.secondary)),
                  ),
                  const SizedBox(height: 16),
                  if (byCategory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin gastos en este periodo', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else ...[
                    CategoryDonutChart(data: byCategory, total: totals.expenses),
                    const SizedBox(height: 16),
                    ...byCategory.map((c) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(c.category.icon, color: c.category.color),
                          title: Text(c.category.label),
                          subtitle: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.percent / 100,
                              color: c.category.color,
                              backgroundColor: AppColors.chartGrid,
                              minHeight: 5,
                            ),
                          ),
                          trailing: Text(
                            '${Format.money(c.amount)}\n${c.percent.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "Gastaste 12% menos que el periodo anterior"
  Widget _comparison(double now, double before) {
    final word = _mode == PeriodMode.semana ? 'la semana' : 'el mes';
    if (before <= 0) {
      return Text('Sin datos de $word anterior para comparar',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    final diff = (now - before) / before * 100;
    final less = diff <= 0;
    return Text(
      'Gastaste ${diff.abs().toStringAsFixed(0)}% ${less ? 'menos' : 'más'} que $word anterior',
      style: TextStyle(color: less ? AppColors.income : AppColors.expense, fontSize: 12),
    );
  }

  Widget _legend(Color color, String text) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      );
}
