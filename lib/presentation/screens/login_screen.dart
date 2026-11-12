// Login y registro. Tambien permite entrar con huella si el usuario la activo.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/repository_exception.dart';
import '../providers/auth_provider.dart';
import '../widgets/hardware_feedback.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _hidePassword = true;
  late Future<bool> _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _biometricAvailable = context.read<AuthProvider>().canUseBiometricLogin();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      if (_isRegister) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } on RepositoryException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, 'Algo salió mal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final result = await context.read<AuthProvider>().loginWithBiometrics();
    if (!mounted) return;
    if (result.isOk) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      showHardwareError(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'finto-logo',
                  child: Image.asset('assets/images/logo-mark.png', height: 80),
                ),
                const SizedBox(height: 12),
                const Text('Finto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: 4)),
                const Text('Tus finanzas en orden',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 32),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Iniciar sesión')),
                    ButtonSegment(value: true, label: Text('Crear cuenta')),
                  ],
                  selected: {_isRegister},
                  onSelectionChanged: (s) => setState(() => _isRegister = s.first),
                ),
                const SizedBox(height: 20),
                // El campo de nombre aparece/desaparece con animacion
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _isRegister
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _hidePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isRegister ? 'Crear cuenta' : 'Entrar'),
                ),
                const SizedBox(height: 16),
                // Solo se muestra si hay huella activada en este telefono
                FutureBuilder<bool>(
                  future: _biometricAvailable,
                  builder: (context, snap) {
                    if (snap.data != true || _isRegister) return const SizedBox.shrink();
                    return OutlinedButton.icon(
                      onPressed: _biometricLogin,
                      icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                      label: const Text('Entrar con huella / rostro'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
