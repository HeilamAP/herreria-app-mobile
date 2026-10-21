import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'foto_store.dart';

FotoStore crearFotoStore() => _FotoStoreNavegador();

/// Versión web (solo para pruebas): guarda la foto en el almacenamiento del navegador.
/// El navegador da poco espacio, así que caben pocas fotos.
class _FotoStoreNavegador implements FotoStore {
  String _clave(String id) => 'ayoy_$id';

  @override
  Future<String> guardar(Uint8List bytes) async {
    final id = nuevoIdFoto();
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_clave(id), base64Encode(bytes));
    } catch (e) {
      // Sin espacio: la foto se ve mientras la app esté abierta, pero no se conserva.
      if (kDebugMode) print('No se pudo guardar la foto en el navegador: $e');
    }
    return id;
  }

  @override
  Future<Uint8List?> leer(String id) async {
    final texto = (await SharedPreferences.getInstance()).getString(_clave(id));
    return texto == null ? null : base64Decode(texto);
  }

  @override
  Future<void> borrar(String id) async => (await SharedPreferences.getInstance()).remove(_clave(id));
}
