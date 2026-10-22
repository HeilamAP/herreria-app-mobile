import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import 'gastos_screen.dart';
import 'resumen_screen.dart';
import 'trabajos_screen.dart';
import 'ui.dart';

/// Pantalla principal de Jose y Nefy: 3 pestañas grandes.
class EncargadoShell extends StatefulWidget {
  const EncargadoShell({super.key});

  @override
  State<EncargadoShell> createState() => _EncargadoShellState();
}

class _EncargadoShellState extends State<EncargadoShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Avisa si se rescató una foto que se tomó cuando Android cerró la app.
    final storage = context.read<StorageService>();
    final n = storage.fotosRecuperadas;
    if (n > 0) {
      storage.fotosRecuperadas = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(n == 1 ? 'Se guardó la foto que tomó.' : 'Se guardaron las $n fotos que tomó.',
              style: const TextStyle(fontSize: 18)),
          behavior: SnackBarBehavior.floating,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final nombre = auth.currentUser?.nombre.split(' ').first ?? '';

    return EncargadoPage(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: EC.fondo,
          surfaceTintColor: EC.fondo,
          toolbarHeight: 72,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $nombre', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
              Text(nombreEquipo(auth.currentUser?.equipoId ?? ''), style: TextStyle(fontSize: 16, color: EC.textoSuave)),
            ],
          ),
          actions: [
            const BotonAspecto(),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: auth.logout,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), side: BorderSide(color: EC.borde)),
                icon: Icon(Icons.logout, color: EC.textoSuave),
                label: Text('Salir', style: TextStyle(fontSize: 17, color: EC.textoSuave)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: IndexedStack(
                index: _tab,
                children: const [TrabajosDiaScreen(), GastosEquipoScreen(), ResumenEquipoScreen()],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 80,
            backgroundColor: EC.fondo,
            indicatorColor: EC.acentoFondo,
            labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                  fontSize: 16,
                  fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                  color: s.contains(WidgetState.selected) ? EC.acentoTexto : EC.textoSuave,
                )),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                  size: 30,
                  color: s.contains(WidgetState.selected) ? EC.acentoTexto : EC.textoSuave,
                )),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Trabajos'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Gastos'),
              NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Resumen'),
            ],
          ),
        ),
      ),
    );
  }
}
