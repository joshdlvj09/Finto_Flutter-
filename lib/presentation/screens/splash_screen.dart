// Pantalla inicial: muestra el logo mientras revisa si habia una sesion guardada
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    // Esperamos minimo un momento para que se vea la animacion del logo
    final results = await Future.wait([
      auth.restoreSession(),
      Future.delayed(const Duration(milliseconds: 900)),
    ]);
    if (!mounted) return;
    final logged = results.first as bool;
    Navigator.pushReplacementNamed(context, logged ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) => Opacity(
            opacity: ((scale - 0.6) / 0.4).clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Hero(tag: 'finto-logo', child: _Logo(size: 96)),
              const SizedBox(height: 16),
              const Text('Finto',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: 4)),
              const SizedBox(height: 28),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) => Image.asset('assets/images/logo-mark.png', width: size, height: size);
}
