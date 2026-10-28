import 'dart:math' as math;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../models/marca.dart';
import '../models/visita_agenda.dart';
import 'app_engine_service.dart';

/// GPS y mapa, separados para que las pruebas usen uno de mentira (ver [UbicadorFijo]).
abstract class Ubicador {
  /// La hora de ahora y, si se puede, dónde está el celular. Nunca falla: sin permiso
  /// o sin señal regresa solo la hora.
  Future<Marca> marcar({bool pedirPermiso = true});

  /// Dónde queda una dirección en el mapa (necesita internet). null si no se encontró.
  Future<(double, double)?> ubicarDireccion(String consulta);

  /// Pide el permiso de ubicación si nunca se ha pedido (antes de abrir la cámara, para que
  /// el aviso de Android no salga encima de ella).
  Future<void> pedirPermiso();
}

class UbicadorGps implements Ubicador {
  @override
  Future<void> pedirPermiso() async {
    try {
      if (await Geolocator.checkPermission() == LocationPermission.denied) await Geolocator.requestPermission();
    } catch (_) {}
  }

  @override
  Future<Marca> marcar({bool pedirPermiso = true}) async {
    final ahora = DateTime.now();
    Marca deposicion(Position p) =>
        Marca(hora: ahora, lat: p.latitude, lng: p.longitude, precisionM: p.accuracy, falsa: p.isMocked);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return Marca(hora: ahora);
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied && pedirPermiso) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) return Marca(hora: ahora);
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
        );
        return deposicion(p);
      } catch (_) {
        // Sin señal a tiempo (p. ej. bajo techo): sirve la última ubicación si es de hace poco.
        final p = await Geolocator.getLastKnownPosition();
        if (p != null && ahora.difference(p.timestamp).inMinutes.abs() <= 5) return deposicion(p);
        return Marca(hora: ahora);
      }
    } catch (_) {
      return Marca(hora: ahora);
    }
  }

  @override
  Future<(double, double)?> ubicarDireccion(String consulta) async {
    try {
      final r = await geo.Geocoding().locationFromAddress(consulta);
      return r.isEmpty ? null : (r.first.latitude, r.first.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// Para pruebas: siempre da la misma ubicación.
class UbicadorFijo implements Ubicador {
  Marca? marca;
  (double, double)? domicilio;
  UbicadorFijo({this.marca, this.domicilio});

  @override
  Future<void> pedirPermiso() async {}

  @override
  Future<Marca> marcar({bool pedirPermiso = true}) async => marca ?? Marca(hora: DateTime.now());

  @override
  Future<(double, double)?> ubicarDireccion(String consulta) async => domicilio;
}

Ubicador ubicador = UbicadorGps();

/// Distancia en metros entre dos puntos (fórmula del haversine).
double distanciaM(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double g) => g * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Hasta aquí cuenta como "en el domicilio" (el GPS y el mapa tienen su margen de error).
const radioDomicilioM = 200.0;

/// Más lejos que esto se le avisa al administrador.
const avisoLejosM = 500.0;

/// Metros entre una marca y la dirección del trabajo; null si no se puede comparar.
double? distanciaAlDomicilio(VisitaAgenda t, Marca m) =>
    m.conGps && t.domicilioUbicado ? distanciaM(m.lat!, m.lng!, t.domLat!, t.domLng!) : null;

bool enDomicilio(VisitaAgenda t, Marca m) {
  final d = distanciaAlDomicilio(t, m);
  return d != null && d <= radioDomicilioM && !m.falsa;
}

/// Lo que se le pregunta al mapa. Los cruzamientos ("x 53 y 55") confunden a los
/// buscadores, así que se usa calle, número, colonia y municipio.
String consultaMapa(VisitaAgenda t) {
  final p = t.partes;
  String base;
  if (p != null && p.calle.trim().isNotEmpty) {
    final calle = RegExp(r'^\d').hasMatch(p.calle.trim()) ? 'Calle ${p.calle.trim()}' : p.calle.trim();
    base = [
      [calle, p.numero.trim()].where((x) => x.isNotEmpty).join(' '),
      p.colonia.trim(),
      p.municipio.trim().isEmpty ? 'Mérida' : p.municipio.trim(),
    ].where((x) => x.isNotEmpty).join(', ');
  } else {
    base = t.direccion.replaceAll(RegExp(r'\s+x\s+\d+[A-Za-z]?(\s+y\s+\d+[A-Za-z]?)?', caseSensitive: false), '').replaceAll('#', '');
  }
  return '$base, Yucatán, México';
}

/// Toma la marca de ahora y, al mismo tiempo, ubica la dirección del trabajo en el mapa
/// si todavía no se sabe dónde queda (para poder comparar).
Future<Marca> tomarMarca(AppEngineService engine, String trabajoId) async {
  final t = engine.visitaPorId(trabajoId);
  final domicilio = t == null || t.direccion.trim().isEmpty || t.domicilioUbicado
      ? Future.value(null)
      : ubicador.ubicarDireccion(consultaMapa(t));
  final marca = await ubicador.marcar();
  final p = await domicilio;
  if (p != null && t != null) engine.guardarDomicilio(trabajoId, p.$1, p.$2, t.direccion);
  return marca;
}
