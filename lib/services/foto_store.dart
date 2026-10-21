import 'dart:typed_data';
import 'foto_store_web.dart' if (dart.library.io) 'foto_store_io.dart' as plataforma;

/// Guarda las fotos de los trabajos aparte de los demás datos (son pesadas).
/// En Android se guardan como archivos en la memoria de la app; en la versión
/// web de pruebas, en el almacenamiento del navegador.
abstract class FotoStore {
  Future<String> guardar(Uint8List bytes);
  Future<Uint8List?> leer(String id);
  Future<void> borrar(String id);
}

/// Almacén que usa la app. Las pruebas lo reemplazan por [FotoStoreMemoria].
FotoStore fotoStore = plataforma.crearFotoStore();

/// Fotos ya leídas, para no volver a cargarlas cada vez que se dibuja la pantalla.
final _cache = <String, Uint8List>{};

Future<Uint8List?> leerFoto(String id) async {
  final enCache = _cache[id];
  if (enCache != null) return enCache;
  final bytes = await fotoStore.leer(id);
  if (bytes != null) _cache[id] = bytes;
  return bytes;
}

Future<String> guardarFoto(Uint8List bytes) async {
  final id = await fotoStore.guardar(bytes);
  _cache[id] = bytes;
  return id;
}

Future<void> borrarFoto(String id) async {
  _cache.remove(id);
  await fotoStore.borrar(id);
}

String nuevoIdFoto() => 'foto_${DateTime.now().microsecondsSinceEpoch}';

class FotoStoreMemoria implements FotoStore {
  final fotos = <String, Uint8List>{};

  @override
  Future<String> guardar(Uint8List bytes) async {
    final id = nuevoIdFoto();
    fotos[id] = bytes;
    return id;
  }

  @override
  Future<Uint8List?> leer(String id) async => fotos[id];

  @override
  Future<void> borrar(String id) async => fotos.remove(id);
}
