// Perfil: huella, cambiar contrasena, restablecer datos, cerrar sesion y eliminar cuenta
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/repository_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/movement_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/hardware_feedback.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final count = context.watch<MovementProvider>().movements.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      drawer: const AppDrawer(currentRoute: AppRoutes.profile),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(user?.initials ?? '',
                  style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
          Text(user?.email ?? '',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          Text('$count movimientos guardados',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                  title: const Text('Entrar con huella / rostro'),
                  subtitle: const Text('Inicia sesión sin escribir la contraseña',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  value: auth.biometricEnabled,
                  onChanged: (v) async {
                    final r = await context.read<AuthProvider>().setBiometric(v);
                    if (!context.mounted) return;
                    if (r.isOk) {
                      showMessage(context, v ? 'Huella activada' : 'Huella desactivada');
                    } else {
                      showHardwareError(context, r);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: AppColors.secondary),
                  title: const Text('Cambiar contraseña'),
                  onTap: () => _changePassword(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restart_alt, color: AppColors.secondary),
                  title: const Text('Restablecer datos'),
                  subtitle: const Text('Borra todos tus movimientos',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () => _resetData(context),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.secondary),
                  title: const Text('Cerrar sesión'),
                  onTap: () => _logout(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.expense),
                  title: const Text('Eliminar cuenta', style: TextStyle(color: AppColors.expense)),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: const TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _resetData(BuildContext context) async {
    if (!await _confirm(context, '¿Restablecer datos?', 'Se borrarán todos tus movimientos y fotos.', 'Borrar')) {
      return;
    }
    if (!context.mounted) return;
    try {
      await context.read<MovementProvider>().resetAll();
      if (context.mounted) showMessage(context, 'Datos restablecidos');
    } on RepositoryException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  Future<void> _logout(BuildContext context) async {
    context.read<MovementProvider>().clear();
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (!await _confirm(context, '¿Eliminar cuenta?',
        'Se borrará tu cuenta y todos tus movimientos. No se puede deshacer.', 'Eliminar')) {
      return;
    }
    if (!context.mounted) return;
    try {
      final movements = context.read<MovementProvider>();
      await movements.resetAll(); // borra tambien las fotos
      movements.clear();
      if (!context.mounted) return;
      await context.read<AuthProvider>().deleteAccount();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } on RepositoryException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual')),
            const SizedBox(height: 12),
            TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AuthProvider>().changePassword(current.text, next.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) showMessage(context, 'Contraseña actualizada');
              } on AuthException catch (e) {
                if (context.mounted) showMessage(context, e.message);
              } on RepositoryException catch (e) {
                if (context.mounted) showMessage(context, e.message);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
  }
}
