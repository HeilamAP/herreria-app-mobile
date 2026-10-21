import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/aspecto_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/app_engine_service.dart';
import 'theme/app_theme.dart';
import 'theme/paleta.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/encargado/encargado_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(PortonesApp(storageService: storageService));
}

class PortonesApp extends StatefulWidget {
  final StorageService storageService;

  const PortonesApp({super.key, required this.storageService});

  @override
  State<PortonesApp> createState() => _PortonesAppState();
}

class _PortonesAppState extends State<PortonesApp> {
  late final AspectoService _aspecto = AspectoService(storage: widget.storageService);

  @override
  void dispose() {
    _aspecto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: widget.storageService),
        ChangeNotifierProvider<AspectoService>.value(value: _aspecto),
        ChangeNotifierProxyProvider<StorageService, AuthService>(
          create: (ctx) => AuthService(storage: widget.storageService),
          update: (ctx, storage, previous) => previous ?? AuthService(storage: storage),
        ),
        ChangeNotifierProxyProvider<StorageService, AppEngineService>(
          create: (ctx) => AppEngineService(storage: widget.storageService),
          update: (ctx, storage, previous) => previous ?? AppEngineService(storage: storage),
        ),
      ],
      child: Consumer2<AuthService, AspectoService>(
        builder: (context, auth, aspecto, child) {
          // Los colores de todas las pantallas salen de la paleta activa. Al cambiar de
          // modo se vuelve a construir la app completa (por eso la clave) para aplicarlos.
          EC.usarOscuro(aspecto.oscuro);
          return MaterialApp(
            key: ValueKey(aspecto.oscuro),
            title: 'Ay Oy Herrería Artística en General',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.encargadoTheme,
            locale: const Locale('es', 'ES'),
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: !auth.isLoggedIn
                ? const LoginScreen()
                : auth.isAdmin
                    ? const MainNavigationScreen()
                    : const EncargadoShell(),
          );
        },
      ),
    );
  }
}
