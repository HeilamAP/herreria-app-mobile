import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'foto_store.dart';
import 'sello_foto.dart';
import 'storage_service.dart';
import 'ubicacion.dart';

/// En celulares con poca memoria, Android puede cerrar la app mientras la cámara
/// está abierta. La foto no se pierde: al volver a abrir la app se rescata y se
/// agrega al trabajo que se estaba fotografiando (con su sello, si era de la cámara).
Future<void> recuperarFotosPerdidas(StorageService storage) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final trabajoId = storage.fotoPendiente;
  if (trabajoId == null) return;
  try {
    final perdidas = await ImagePicker().retrieveLostData();
    final archivos = perdidas.files ?? const <XFile>[];
    final visita = storage.data.agenda.where((v) => v.id == trabajoId).firstOrNull;
    if (archivos.isNotEmpty && visita != null) {
      // El permiso ya se pidió antes de abrir la cámara: aquí no se vuelve a preguntar.
      final marca = storage.fotoPendienteDeCamara ? await ubicador.marcar(pedirPermiso: false) : null;
      final nuevas = <String>[];
      for (final archivo in archivos) {
        var bytes = await archivo.readAsBytes();
        if (marca != null) bytes = await sellarFotoDeTrabajo(bytes, visita, marca);
        final id = await guardarFoto(bytes);
        if (marca != null) visita.marcasFotos[id] = marca;
        nuevas.add(id);
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
