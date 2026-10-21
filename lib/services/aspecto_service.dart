import 'package:flutter/widgets.dart';
import 'storage_service.dart';

/// Modo claro / oscuro / "como el celular". Lo elige cada persona en su teléfono.
class AspectoService extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storage;
  late String _aspecto;
  late Brightness _brilloSistema;
  bool _cambioDelSistemaPendiente = false;

  AspectoService({required this.storage}) {
    _aspecto = storage.aspecto;
    _brilloSistema = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.addObserver(this);
  }

  /// 'claro', 'oscuro' o 'sistema'.
  String get aspecto => _aspecto;

  bool get oscuro => _aspecto == 'oscuro' || (_aspecto == 'sistema' && _brilloSistema == Brightness.dark);

  Future<void> cambiar(String aspecto) async {
    if (aspecto == _aspecto) return;
    _aspecto = aspecto;
    _brilloSistema = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    await storage.guardarAspecto(aspecto);
    notifyListeners();
  }

  // Si el celular cambia solo a oscuro (por ejemplo, al anochecer) mientras se usa la
  // app, el cambio se aplica al volver a abrirla: cambiar de modo reinicia las pantallas
  // y no queremos que se pierda lo que alguien está capturando.
  @override
  void didChangePlatformBrightness() {
    if (_aspecto == 'sistema') _cambioDelSistemaPendiente = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cambioDelSistemaPendiente) {
      _cambioDelSistemaPendiente = false;
      final nuevo = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (nuevo != _brilloSistema) {
        _brilloSistema = nuevo;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
