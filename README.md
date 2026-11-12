# Finto (Flutter)

App móvil de finanzas personales hecha en Flutter. Sirve para registrar ingresos y gastos como si fuera un diario: cada movimiento puede llevar la foto del ticket, una nota dictada por voz y la ubicación GPS de dónde se registró.

Es la versión en Flutter de [Finto (Expo / React Native)](https://github.com/joshdlvj09/Finto), adaptada para el Parcial 2. Todo se guarda localmente en el teléfono con SQLite.

## Funciones

- Registro e inicio de sesión locales (la contraseña se guarda con hash y sal)
- Inicio de sesión con huella / Face ID (`local_auth`)
- Gastos e ingresos con categoría, nota, fecha y factura (no / pendiente / hecha)
- Registrar varios movimientos a la vez ("Agregar otro movimiento")
- **Cámara y galería:** foto del ticket (`image_picker`)
- **Dictado por voz:** la nota se escribe hablando (`speech_to_text`)
- **GPS y mapa:** la ubicación se captura al crear un movimiento y en el detalle se ve en un mapa interactivo (`flutter_map`) con un botón para abrirla en Google Maps
- Análisis semanal y mensual: balance, comparación con el periodo anterior, gráfica de barras y de dona por categoría
- Perfil: activar huella, cambiar contraseña, restablecer datos, cerrar sesión y eliminar cuenta

## Cómo cumple los requisitos del parcial

| Requisito | Dónde está |
|---|---|
| Scaffold, AppBar y Drawer | Todas las pantallas; el menú está en `widgets/app_drawer.dart` |
| Rutas nombradas y Navigator | `core/routes/app_routes.dart` (`/inicio`, `/movimiento`, `/nuevo`, `/analisis`, `/perfil`) |
| Hero de la lista al detalle | `widgets/movement_visual.dart` (foto o ícono del movimiento) y el logo entre Splash y Login |
| Otras animaciones | Transición fade entre secciones, lista escalonada, balance animado, gráficas que crecen, `AnimatedSize`/`AnimatedSwitcher` |
| SQLite para registros y metadatos | `data/database/app_database.dart`; la ruta de la foto y las coordenadas se guardan como JSON en la columna `metadata` |
| SharedPreferences | `services/session_service.dart` (sesión y usuario con huella) |
| try-catch y FutureBuilder | Repositorios lanzan `RepositoryException`; Inicio carga con `FutureBuilder` + `CircularProgressIndicator` y pantalla de error con "Reintentar" |
| Permisos denegados | `services/hardware_result.dart`: cada servicio regresa si fue cancelado, negado, negado para siempre (botón "Ajustes") o si el GPS está apagado (botón "Activar"). La app nunca se cierra por eso. |

## Estructura (por capas)

```
lib/
├── main.dart                 Crea servicios y repositorios y los inyecta con Provider
├── core/
│   ├── constants/            Tema (colores) y catálogo de categorías
│   ├── routes/               Rutas nombradas
│   └── utils/                Formato de dinero/fechas y cálculo de periodos
├── data/
│   ├── database/             Conexión SQLite (singleton)
│   ├── models/               Movement, EntryMetadata (JSON), AppUser
│   └── repositories/         Interfaces + implementación con SQLite
├── services/                 Cámara, voz, GPS, biometría, sesión, hash de contraseña
└── presentation/
    ├── providers/            AuthProvider y MovementProvider (estado)
    ├── screens/              Splash, Login, Inicio, Detalle, Formulario, Análisis, Perfil
    └── widgets/              Drawer, fila de movimiento, gráficas, etc.
```

Las pantallas solo dependen de los providers, y los providers dependen de interfaces (`MovementRepository`, `UserRepository`), no de SQLite directamente.

## Cómo correrlo

Requisitos: Flutter 3.27 o más nuevo, y un teléfono o emulador (la cámara, el micrófono y la huella funcionan mejor en un teléfono real).

```bash
# 1. Genera las carpetas android/ios que faltan y agrega los permisos de iOS
./tool/setup.sh

# 2. Corre la app
flutter run
```

`tool/setup.sh` usa `flutter create`, que no sobreescribe los archivos que ya vienen en el repo (`AndroidManifest.xml` con los permisos y `MainActivity.kt`, que usa `FlutterFragmentActivity` para la huella).

Pruebas:

```bash
flutter test
```

## Notas

- El mapa usa OpenStreetMap, así que no necesita API key de Google. El botón "Google Maps" abre la app de Google Maps con las coordenadas guardadas.
- En Android el dictado puede necesitar internet, según el teléfono.
- En el emulador de Android hay que poner una ubicación falsa (Extended controls → Location) para probar el GPS.
