import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import '../models/marca.dart';
import '../models/visita_agenda.dart';
import 'ubicacion.dart';

const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "Mié 28 oct 2026 · 10:42 a.m."
String fechaHoraSello(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]} ${d.year} · '
      '$h12:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
}

/// Lo que dice el sello de una foto del trabajo (sin coordenadas: al cliente no le dicen nada).
List<String> lineasSello(VisitaAgenda t, DateTime hora) => [
      if (t.direccion.trim().isNotEmpty) t.direccion.trim(),
      fechaHoraSello(hora),
      [
        t.tipo,
        if (t.cliente.trim().isNotEmpty) t.cliente.trim(),
        'Equipo ${t.equipoId.replaceAll('equipo', '')}',
      ].join(' · '),
    ];

/// Pone el sello de evidencia a una foto del trabajo. Si algo falla, regresa la foto como estaba
/// (es mejor guardar la foto sin sello que perderla).
Future<Uint8List> sellarFotoDeTrabajo(Uint8List foto, VisitaAgenda t, Marca m) async {
  try {
    return await sellarFoto(foto, lineas: lineasSello(t, m.hora), etiqueta: enDomicilio(t, m) ? 'En el domicilio' : null);
  } catch (e) {
    debugPrint('No se pudo poner el sello: $e');
    return foto;
  }
}

/// Dibuja una franja oscura abajo de la foto con el nombre del negocio, la [etiqueta] (verde)
/// y las [lineas]. El sello queda pegado a la imagen: no se pierde al mandarla por WhatsApp.
Future<Uint8List> sellarFoto(Uint8List original, {required List<String> lineas, String? etiqueta}) async {
  final codec = await ui.instantiateImageCodec(original);
  final foto = (await codec.getNextFrame()).image;
  final w = foto.width.toDouble(), h = foto.height.toDouble();
  final letra = math.max(14.0, math.min(w, h) / 30); // tamaño relativo a la foto
  final margen = letra * 0.8;
  final ancho = w - margen * 2;

  TextPainter texto(String s, {double escala = 1, FontWeight peso = FontWeight.w400, Color color = const Color(0xFFFFFFFF)}) =>
      TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: letra * escala, fontWeight: peso, color: color, height: 1.25)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: ancho);

  final titulo = texto('AY OY · Herrería Artística', escala: 0.9, peso: FontWeight.w700);
  final etiq = etiqueta == null ? null : texto(etiqueta, escala: 0.8, peso: FontWeight.w700);
  final cuerpo = [for (final l in lineas) texto(l)];
  final altoTitulo = math.max(titulo.height, etiq == null ? 0.0 : etiq.height + letra * 0.3);
  final alto = margen * 2 + altoTitulo + letra * 0.25 + cuerpo.fold(0.0, (s, p) => s + p.height);

  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawImage(foto, Offset.zero, Paint());
  c.drawRect(Rect.fromLTWH(0, h - alto, w, alto), Paint()..color = const Color(0xA6000000));
  var y = h - alto + margen;
  titulo.paint(c, Offset(margen, y));
  if (etiq != null) {
    final pad = letra * 0.3;
    final caja = Rect.fromLTWH(w - margen - etiq.width - pad * 2, y, etiq.width + pad * 2, etiq.height + pad);
    c.drawRRect(RRect.fromRectAndRadius(caja, Radius.circular(pad)), Paint()..color = const Color(0xFF1D9E75));
    etiq.paint(c, Offset(caja.left + pad, caja.top + pad / 2));
  }
  y += altoTitulo + letra * 0.25;
  for (final p in cuerpo) {
    p.paint(c, Offset(margen, y));
    y += p.height;
  }

  final (anchoPx, altoPx) = (foto.width, foto.height);
  final sellada = await rec.endRecording().toImage(anchoPx, altoPx);
  final datos = await sellada.toByteData(format: ui.ImageByteFormat.rawRgba);
  foto.dispose();
  sellada.dispose();
  // Pasar a JPG es pesado: se hace fuera de la pantalla para que no se trabe.
  return compute(_aJpg, (datos!.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes), anchoPx, altoPx));
}

Uint8List _aJpg((Uint8List, int, int) d) {
  final imagen = img.Image.fromBytes(width: d.$2, height: d.$3, bytes: d.$1.buffer, bytesOffset: d.$1.offsetInBytes, numChannels: 4, order: img.ChannelOrder.rgba);
  return img.encodeJpg(imagen, quality: 80);
}
