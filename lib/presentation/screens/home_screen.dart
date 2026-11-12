// Inicio: balance y lista de movimientos (el "diario" de Finto)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../data/models/movement.dart';
import '../providers/auth_provider.dart';
import '../providers/movement_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movement_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Movement>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<List<Movement>> _load() {
    final userId = context.read<AuthProvider>().user!.id!;
    return context.read<MovementProvider>().load(userId);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _loadFuture = f);
    await f.catchError((_) => <Movement>[]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.firstName ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Análisis',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.form),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: FutureBuilder<List<Movement>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          // 1) Cargando
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          // 2) Error al leer la base de datos
          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          // 3) Datos listos: escuchamos el provider para ver altas / bajas al momento
          return Consumer<MovementProvider>(
            builder: (context, provider, _) {
              final list = provider.movements;
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.isEmpty ? 2 : list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _BalanceCard(provider: provider);
                    if (list.isEmpty) return const _EmptyView();
                    final m = list[i - 1];
                    return _FadeInItem(
                      index: i,
                      child: MovementTile(
                        movement: m,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.detail, arguments: m.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final MovementProvider provider;
  const _BalanceCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.totals;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balance', style: TextStyle(color: AppColors.secondary)),
            const SizedBox(height: 4),
            // El numero se anima cuando cambia el balance
            TweenAnimationBuilder<double>(
              tween: Tween(end: t.balance),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                '${value < 0 ? '-' : ''}${Format.money(value)}',
                style: TextStyle(
                  color: value < 0 ? AppColors.expense : AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _mini(Icons.arrow_downward, 'Ingresos', t.income, AppColors.income),
                const SizedBox(width: 12),
                _mini(Icons.arrow_upward, 'Gastos', t.expenses, AppColors.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String label, double value, Color color) => Expanded(
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(Format.money(value), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
}

// Entrada escalonada de cada fila de la lista
class _FadeInItem extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeInItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 10)) * 40;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOut,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Aún no tienes movimientos',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            SizedBox(height: 4),
            Text('Toca "Nuevo" para registrar tu primer gasto o ingreso',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
}
