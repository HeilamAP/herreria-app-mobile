import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'seguridad.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  static const _intentosPermitidos = 5;
  static const _esperaBloqueo = Duration(seconds: 30);

  final StorageService storage;
  Usuario? _currentUser;
  final Map<String, int> _fallos = {};
  final Map<String, DateTime> _bloqueadoHasta = {};

  AuthService({required this.storage});

  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin =>
      _currentUser != null &&
      _currentUser!.rol.toLowerCase() == 'administrador';
  bool get isEmpleado =>
      _currentUser != null && _currentUser!.rol.toLowerCase() == 'empleado';

  List<Usuario> get encargados =>
      storage.data.usuarios.where((u) => !u.isAdmin).toList();

  /// Segundos que faltan para poder volver a intentar, o 0 si no hay bloqueo.
  int segundosBloqueado(String userId) {
    final hasta = _bloqueadoHasta[userId];
    if (hasta == null) return 0;
    final faltan = hasta.difference(DateTime.now()).inSeconds;
    return faltan > 0 ? faltan + 1 : 0;
  }

  bool login(String username, String password, {required Function(String) onError}) {
    if (username.trim().isEmpty || password.isEmpty) {
      onError('Escribe tu usuario y contraseña.');
      return false;
    }
    final user = storage.data.usuarios.where(
      (u) => u.isAdmin && u.username.trim().toLowerCase() == username.trim().toLowerCase(),
    ).firstOrNull;

    final clave = user?.id ?? 'admin:${username.toLowerCase()}';
    final espera = segundosBloqueado(clave);
    if (espera > 0) {
      onError('Demasiados intentos. Espera $espera segundos.');
      return false;
    }
    if (user == null || !Seguridad.verificar(password, user.password)) {
      _registrarFallo(clave);
      onError('Usuario o contraseña incorrectos.');
      return false;
    }
    _entrar(user);
    return true;
  }

  /// Devuelve null si entró, o el mensaje de error.
  String? loginConPin(Usuario user, String pin) {
    final espera = segundosBloqueado(user.id);
    if (espera > 0) return 'Espera $espera segundos e inténtalo otra vez.';
    if (!Seguridad.verificar(pin, user.pin)) {
      _registrarFallo(user.id);
      final quedan = _intentosPermitidos - (_fallos[user.id] ?? 0);
      if (segundosBloqueado(user.id) > 0) {
        return 'PIN incorrecto. Espera 30 segundos e inténtalo otra vez.';
      }
      return 'PIN incorrecto. Te quedan $quedan intentos.';
    }
    _entrar(user);
    return null;
  }

  void crearPinYEntrar(Usuario user, String pin) {
    user.pin = Seguridad.cifrar(pin);
    storage.saveData();
    _entrar(user);
  }

  /// El administrador borra el PIN de un encargado que lo olvidó; al entrar creará uno nuevo.
  void borrarPin(Usuario user) {
    user.pin = '';
    _fallos.remove(user.id);
    _bloqueadoHasta.remove(user.id);
    storage.saveData();
    notifyListeners();
  }

  bool cambiarPassword(String actual, String nueva) {
    final user = _currentUser;
    if (user == null || !Seguridad.verificar(actual, user.password)) return false;
    user.password = Seguridad.cifrar(nueva);
    storage.saveData();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void _entrar(Usuario user) {
    _fallos.remove(user.id);
    _bloqueadoHasta.remove(user.id);
    _currentUser = user;
    notifyListeners();
  }

  void _registrarFallo(String clave) {
    final n = (_fallos[clave] ?? 0) + 1;
    _fallos[clave] = n;
    if (n >= _intentosPermitidos) {
      _fallos[clave] = 0;
      _bloqueadoHasta[clave] = DateTime.now().add(_esperaBloqueo);
    }
  }
}
