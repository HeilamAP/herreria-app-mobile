import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'foto_store.dart';
import 'storage_service.dart';

/// En celulares con poca memoria, Android puede cerrar la app mientras la cámara
/// está abierta. La foto no se pierde: al volver a abrir la app se rescata y se
/// agrega al trabajo que se estaba fotografiando.
Future<void> recuperarFotosPerdidas(StorageService storage) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final trabajoId = storage.fotoPendiente;
  if (trabajoId == null) return;
  try {
    final perdidas = await ImagePicker().retrieveLostData();
    final archivos = perdidas.files ?? const <XFile>[];
    final visita = storage.data.agenda.where((v) => v.id == trabajoId).firstOrNull;
    if (archivos.isNotEmpty && visita != null) {
      final nuevas = <String>[];
      for (final archivo in archivos) {
        nuevas.add(await guardarFoto(await archivo.readAsBytes()));
      }
      visita.fotos = [...visita.fotos, ...nuevas];
      await storage.saveData();
      storage.fotosRecuperadas = nuevas.length;
    }
  } catch (e) {
    debugPrint('No se pudo rescatar la foto: $e');
  } finally {
    await storage.guardarFotoPendiente(null);
  }
}
