import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'foto_store.dart';

FotoStore crearFotoStore() => _FotoStoreArchivos();

/// Android/iOS: cada foto es un archivo .jpg en la carpeta de documentos de la app.
class _FotoStoreArchivos implements FotoStore {
  Directory? _carpeta;

  Future<Directory> _dir() async {
    if (_carpeta != null) return _carpeta!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}fotos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _carpeta = dir;
  }

  Future<File> _archivo(String id) async => File('${(await _dir()).path}${Platform.pathSeparator}$id.jpg');

  @override
  Future<String> guardar(Uint8List bytes) async {
    final id = nuevoIdFoto();
    await (await _archivo(id)).writeAsBytes(bytes, flush: true);
    return id;
  }

  @override
  Future<Uint8List?> leer(String id) async {
    final f = await _archivo(id);
    return await f.exists() ? f.readAsBytes() : null;
  }

  @override
  Future<void> borrar(String id) async {
    final f = await _archivo(id);
    if (await f.exists()) await f.delete();
  }
}
