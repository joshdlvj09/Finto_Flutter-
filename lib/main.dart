// Punto de entrada. Aqui se crean los servicios y repositorios y se inyectan
// con Provider, para que las pantallas no creen sus propias dependencias.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'data/database/app_database.dart';
import 'data/repositories/movement_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/movement_provider.dart';
import 'services/biometric_service.dart';
import 'services/camera_service.dart';
import 'services/location_service.dart';
import 'services/password_hasher.dart';
import 'services/session_service.dart';
import 'services/speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  final db = AppDatabase.instance;
  final UserRepository userRepo = SqliteUserRepository(db);
  final MovementRepository movementRepo = SqliteMovementRepository(db);
  final camera = CameraService();

  runApp(
    MultiProvider(
      providers: [
        Provider<CameraService>.value(value: camera),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userRepo, SessionService(), BiometricService(), PasswordHasher()),
        ),
        ChangeNotifierProvider(create: (_) => MovementProvider(movementRepo, camera)),
      ],
      child: const FintoApp(),
    ),
  );
}

class FintoApp extends StatelessWidget {
  const FintoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
