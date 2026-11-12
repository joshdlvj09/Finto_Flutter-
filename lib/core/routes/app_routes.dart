// Rutas nombradas de la app. Todas las pantallas se abren con Navigator.pushNamed.
import 'package:flutter/material.dart';

import '../../presentation/screens/analytics_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/movement_detail_screen.dart';
import '../../presentation/screens/movement_form_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/inicio';
  static const detail = '/movimiento';
  static const form = '/nuevo';
  static const analytics = '/analisis';
  static const profile = '/perfil';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(settings, const SplashScreen());
      case login:
        return _fade(settings, const LoginScreen());
      case home:
        return _fade(settings, const HomeScreen());
      case detail:
        // Argumento: id del movimiento
        final id = settings.arguments as int;
        return MaterialPageRoute(settings: settings, builder: (_) => MovementDetailScreen(movementId: id));
      case form:
        // Argumento opcional: id del movimiento a editar
        final editId = settings.arguments as int?;
        return MaterialPageRoute(
          settings: settings,
          fullscreenDialog: editId == null,
          builder: (_) => MovementFormScreen(editId: editId),
        );
      case analytics:
        return _fade(settings, const AnalyticsScreen());
      case profile:
        return _fade(settings, const ProfileScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Finto')),
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }

  // Transicion suave (fade + pequeno desplazamiento) para las secciones del Drawer
  static PageRouteBuilder _fade(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
