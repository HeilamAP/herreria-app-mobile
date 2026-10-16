import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

import 'home_dashboard_screen.dart';
import 'ventas_screen.dart';
import 'gastos_screen.dart';
import 'agenda_screen.dart';
import 'empleados_screen.dart';
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

    final List<_NavDestination> destinations = [
      _NavDestination('Inicio', Icons.home_outlined, Icons.home, const HomeDashboardScreen()),
      _NavDestination('Ventas', Icons.point_of_sale_outlined, Icons.point_of_sale, const VentasScreen()),
      _NavDestination('Gastos', Icons.money_off_outlined, Icons.money_off, const GastosScreen()),
      _NavDestination('Agenda', Icons.calendar_month_outlined, Icons.calendar_month, const AgendaScreen()),
      if (auth.isAdmin) _NavDestination('Personal', Icons.people_outline, Icons.people, const EmpleadosScreen()),
      if (auth.isAdmin) _NavDestination('Respaldos', Icons.backup_outlined, Icons.backup, const RespaldosScreen()),
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
                backgroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text('Rol: ${auth.currentUser?.rol}'),
                ),
                const PopupMenuDivider(),
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
