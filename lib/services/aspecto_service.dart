import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Modo claro u oscuro. Lo elige cada persona en su teléfono.
class AspectoService extends ChangeNotifier {
  final StorageService storage;
  late String _aspecto;

  AspectoService({required this.storage}) {
    // Cualquier valor que no sea 'oscuro' (incluido uno guardado de una versión anterior) es claro.
    _aspecto = storage.aspecto == 'oscuro' ? 'oscuro' : 'claro';
  }

  /// 'claro' u 'oscuro'.
  String get aspecto => _aspecto;

  bool get oscuro => _aspecto == 'oscuro';

  Future<void> cambiar(String aspecto) async {
    if (aspecto == _aspecto) return;
    _aspecto = aspecto;
    await storage.guardarAspecto(aspecto);
    notifyListeners();
  }
}
