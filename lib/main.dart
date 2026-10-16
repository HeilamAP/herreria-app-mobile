import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/app_engine_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

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
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: widget.storageService),
        ChangeNotifierProxyProvider<StorageService, AuthService>(
          create: (ctx) => AuthService(storage: widget.storageService),
          update: (ctx, storage, previous) => previous ?? AuthService(storage: storage),
        ),
        ChangeNotifierProxyProvider<StorageService, AppEngineService>(
          create: (ctx) => AppEngineService(storage: widget.storageService),
          update: (ctx, storage, previous) => previous ?? AppEngineService(storage: storage),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, child) {
          return MaterialApp(
            title: 'Ay Oy Herrería Artística en General',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
            home: auth.isLoggedIn
                ? MainNavigationScreen(
                    onToggleTheme: _toggleTheme,
                    isDarkMode: _isDarkMode,
                  )
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
