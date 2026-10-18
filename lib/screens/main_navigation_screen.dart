import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

import 'accesos_screen.dart';
import 'admin_inicio_screen.dart';
import 'empleados_screen.dart';
import 'encargado/trabajos_screen.dart';
import 'encargado/ui.dart';
import 'respaldos_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Ventas y gastos se ven en el Inicio (por equipo); ya no son pestañas aparte.
    final List<_NavDestination> destinations = [
      _NavDestination('Inicio', Icons.home_outlined, Icons.home, const AdminInicioScreen()),
      _NavDestination(
        'Agenda',
        Icons.calendar_month_outlined,
        Icons.calendar_month,
        const EncargadoPage(child: ColoredBox(color: EC.fondo, child: TrabajosDiaScreen(admin: true))),
      ),
      _NavDestination('Personal', Icons.people_outline, Icons.people, const EmpleadosScreen()),
      _NavDestination('Reportes', Icons.description_outlined, Icons.description, const RespaldosScreen()),
    ];

    // Ensure _currentIndex is within bounds
    if (_currentIndex >= destinations.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 2,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.door_sliding_outlined, color: AppTheme.primaryCyan),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ay Oy Herrería en General',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Cambiar Tema',
            onPressed: widget.onToggleTheme,
          ),

          // User badge & logout
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'logout') {
                  auth.logout();
                } else if (val == 'accesos') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccesosScreen()));
                }
              },
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: auth.isAdmin ? AppTheme.accentTeal : AppTheme.infoPurple,
                  child: Text(
                    (auth.currentUser?.nombre.isNotEmpty == true)
                        ? auth.currentUser!.nombre[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                label: Text(
                  auth.currentUser?.nombre ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text('Rol: ${auth.currentUser?.rol}'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'accesos',
                  child: Row(
                    children: [
                      Icon(Icons.key_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('PIN y contraseña'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.dangerRed, size: 18),
                      SizedBox(width: 8),
                      Text('Cerrar Sesión', style: TextStyle(color: AppTheme.dangerRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // NavigationRail for tablets/desktops
          if (MediaQuery.of(context).size.width >= 768)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryCyan),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.title),
                );
              }).toList(),
            ),

          // Main body content view
          Expanded(
            child: destinations[_currentIndex].screen,
          ),
        ],
      ),

      // BottomNavigationBar for phones
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).cardColor,
              selectedItemColor: AppTheme.primaryCyan,
              unselectedItemColor: const Color(0xFF94A3B8),
              items: destinations.map((d) {
                return BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.selectedIcon),
                  label: d.title,
                );
              }).toList(),
            )
          : null,
    );
  }
}

class _NavDestination {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  _NavDestination(this.title, this.icon, this.selectedIcon, this.screen);
}
