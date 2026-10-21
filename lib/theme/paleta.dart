import 'package:flutter/material.dart';

/// Juego de colores de la app. Hay uno claro y uno oscuro, ambos de alto contraste.
class Paleta {
  final Color texto, textoSuave, textoTenue;
  final Color fondo, superficie, borde, bordeFuerte;
  final Color acento, acentoRelleno, acentoFondo, acentoTexto;
  final Color exito, exitoFondo, exitoTexto, exitoBorde;
  final Color peligro, peligroRelleno, peligroFondo, peligroTexto;
  final Color equipo2Fondo, equipo2Borde, equipo2Texto;
  final Color franja;

  const Paleta({
    required this.texto,
    required this.textoSuave,
    required this.textoTenue,
    required this.fondo,
    required this.superficie,
    required this.borde,
    required this.bordeFuerte,
    required this.acento,
    required this.acentoRelleno,
    required this.acentoFondo,
    required this.acentoTexto,
    required this.exito,
    required this.exitoFondo,
    required this.exitoTexto,
    required this.exitoBorde,
    required this.peligro,
    required this.peligroRelleno,
    required this.peligroFondo,
    required this.peligroTexto,
    required this.equipo2Fondo,
    required this.equipo2Borde,
    required this.equipo2Texto,
    required this.franja,
  });

  static const clara = Paleta(
    texto: Color(0xFF0F172A),
    textoSuave: Color(0xFF475569),
    textoTenue: Color(0xFF94A3B8),
    fondo: Color(0xFFFFFFFF),
    superficie: Color(0xFFF1F5F9),
    borde: Color(0xFFCBD5E1),
    bordeFuerte: Color(0xFF64748B),
    acento: Color(0xFF0369A1),
    acentoRelleno: Color(0xFF0369A1),
    acentoFondo: Color(0xFFE0F2FE),
    acentoTexto: Color(0xFF075985),
    exito: Color(0xFF15803D),
    exitoFondo: Color(0xFFDCFCE7),
    exitoTexto: Color(0xFF166534),
    exitoBorde: Color(0xFF86EFAC),
    peligro: Color(0xFFDC2626),
    peligroRelleno: Color(0xFFDC2626),
    peligroFondo: Color(0xFFFEE2E2),
    peligroTexto: Color(0xFF991B1B),
    equipo2Fondo: Color(0xFFE1F5EE),
    equipo2Borde: Color(0xFF1D9E75),
    equipo2Texto: Color(0xFF085041),
    franja: Color(0x08000000),
  );

  /// No es negro puro: fondo gris muy oscuro y tarjetas un tono más claro.
  static const oscura = Paleta(
    texto: Color(0xFFF1F5F9),
    textoSuave: Color(0xFFB6C0CC),
    textoTenue: Color(0xFF7C8794),
    fondo: Color(0xFF121417),
    superficie: Color(0xFF1E2228),
    borde: Color(0xFF3A424D),
    bordeFuerte: Color(0xFF5B6675),
    acento: Color(0xFF4FA3E0),
    acentoRelleno: Color(0xFF1F6FAE),
    acentoFondo: Color(0xFF0F3550),
    acentoTexto: Color(0xFFBFE3FF),
    exito: Color(0xFF1E7A43),
    exitoFondo: Color(0xFF123A22),
    exitoTexto: Color(0xFF9BE7B4),
    exitoBorde: Color(0xFF2F7D4A),
    peligro: Color(0xFFFF7B7B),
    peligroRelleno: Color(0xFFC53030),
    peligroFondo: Color(0xFF3D1717),
    peligroTexto: Color(0xFFFF9C9C),
    equipo2Fondo: Color(0xFF0B3B30),
    equipo2Borde: Color(0xFF3CC79A),
    equipo2Texto: Color(0xFFB5F0DA),
    franja: Color(0x0DFFFFFF),
  );
}

/// Colores de la app según el modo activo (claro u oscuro).
/// Al cambiar de modo, main.dart vuelve a construir toda la app para que se apliquen.
class EC {
  static Paleta _p = Paleta.clara;

  static bool get oscuro => identical(_p, Paleta.oscura);
  static void usarOscuro(bool oscuro) => _p = oscuro ? Paleta.oscura : Paleta.clara;

  static Color get texto => _p.texto;
  static Color get textoSuave => _p.textoSuave;
  static Color get textoTenue => _p.textoTenue;
  static Color get fondo => _p.fondo;
  static Color get superficie => _p.superficie;
  static Color get borde => _p.borde;
  static Color get bordeFuerte => _p.bordeFuerte;
  static Color get acento => _p.acento;
  static Color get acentoRelleno => _p.acentoRelleno;
  static Color get acentoFondo => _p.acentoFondo;
  static Color get acentoTexto => _p.acentoTexto;
  static Color get exito => _p.exito;
  static Color get exitoFondo => _p.exitoFondo;
  static Color get exitoTexto => _p.exitoTexto;
  static Color get exitoBorde => _p.exitoBorde;
  static Color get peligro => _p.peligro;
  static Color get peligroRelleno => _p.peligroRelleno;
  static Color get peligroFondo => _p.peligroFondo;
  static Color get peligroTexto => _p.peligroTexto;
  static Color get equipo2Fondo => _p.equipo2Fondo;
  static Color get equipo2Borde => _p.equipo2Borde;
  static Color get equipo2Texto => _p.equipo2Texto;
  static Color get franja => _p.franja;
}
