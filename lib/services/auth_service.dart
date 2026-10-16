import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService storage;
  Usuario? _currentUser;

  AuthService({required this.storage});

  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin =>
      _currentUser != null &&
      _currentUser!.rol.toLowerCase() == 'administrador';
  bool get isEmpleado =>
      _currentUser != null && _currentUser!.rol.toLowerCase() == 'empleado';

  bool login(String username, String password, {required Function(String) onError}) {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      onError('Ingresa usuario y contraseña.');
      return false;
    }

    final user = storage.data.usuarios.firstWhere(
      (u) =>
          u.username.trim().toLowerCase() == username.trim().toLowerCase() &&
          u.password == password,
      orElse: () => Usuario(id: '', nombre: '', username: '', password: '', rol: ''),
    );

    if (user.id.isEmpty) {
      onError('Usuario o contraseña incorrectos.');
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  bool canAccessTab(int index) {
    if (!isLoggedIn) return false;
    if (isAdmin) return true;

    // Index mapping for Empleado:
    // 0: Resumen (Disabled for Empleado in web app, redirects to Agenda)
    // 1: Ventas (Allowed)
    // 2: Gastos (Allowed)
    // 3: Trabajos (Allowed)
    // 4: Agenda (Allowed)
    // 5: Empleados / Nómina (Admin only)
    // 6: Respaldos (Admin only)
    switch (index) {
      case 1: // Ventas
      case 2: // Gastos
      case 3: // Trabajos
      case 4: // Agenda
        return true;
      default:
        return false;
    }
  }
}
