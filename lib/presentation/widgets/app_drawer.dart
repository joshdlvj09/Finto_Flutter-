// Menu lateral (Drawer) con las secciones principales de la app
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/movement_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(user?.initials ?? '',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(user?.email ?? '',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            _item(context, Icons.home_outlined, 'Inicio', AppRoutes.home),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
              title: const Text('Nuevo movimiento'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.form);
              },
            ),
            _item(context, Icons.bar_chart_rounded, 'Análisis', AppRoutes.analytics),
            _item(context, Icons.person_outline, 'Perfil', AppRoutes.profile),
            const Spacer(),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.expense),
              title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.expense)),
              onTap: () async {
                context.read<MovementProvider>().clear();
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Las secciones reemplazan a la actual para no ir apilando pantallas
  Widget _item(BuildContext context, IconData icon, String label, String route) {
    final selected = route == currentRoute;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : AppColors.secondary),
      title: Text(label,
          style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        if (!selected) {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.settings.name == AppRoutes.home);
        }
      },
    );
  }
}
