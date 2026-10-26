import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/aspecto_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta.dart';

export '../../theme/paleta.dart';

/// Los teléfonos de México tienen 10 números.
const digitosTelefono = 10;

/// Escribe el teléfono como "999 123 4567" (solo toma los números, máximo 10).
String formatoTelefono(String texto) {
  final d = texto.replaceAll(RegExp(r'[^0-9]'), '');
  final n = d.length > digitosTelefono ? d.substring(0, digitosTelefono) : d;
  final b = StringBuffer();
  for (var i = 0; i < n.length; i++) {
    if (i == 3 || i == 6) b.write(' ');
    b.write(n[i]);
  }
  return b.toString();
}

/// Al escribir el teléfono solo deja poner números (máximo 10) y los va separando.
class FormatoTelefono extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final texto = formatoTelefono(nuevo.text);
    // El cursor queda después del mismo número de dígitos que tenía antes de dar formato.
    final cursor = nuevo.selection.end.clamp(0, nuevo.text.length);
    final digitosAntes = nuevo.text.substring(0, cursor).replaceAll(RegExp(r'[^0-9]'), '').length;
    var pos = 0, vistos = 0;
    while (pos < texto.length && vistos < digitosAntes) {
      if (texto[pos] != ' ') vistos++;
      pos++;
    }
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: pos));
  }
}


const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const diasLargos = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const tiposTrabajo = <(String, IconData)>[
  ('Instalación', Icons.build_outlined),
  ('Mantenimiento', Icons.tune),
  ('Reparación', Icons.handyman_outlined),
  ('Medir y cotizar', Icons.straighten),
  ('Soldadura', Icons.local_fire_department_outlined),
  ('Venta', Icons.shopping_cart_outlined),
  ('Otro', Icons.more_horiz),
];

IconData iconoDeTipo(String tipo) =>
    tiposTrabajo.firstWhere((t) => t.$1.toLowerCase() == tipo.toLowerCase(), orElse: () => tiposTrabajo.last).$2;

String nombreEquipo(String equipoId) => switch (equipoId) {
      'equipo1' => 'Equipo 1',
      'equipo2' => 'Equipo 2',
      _ => 'Todos',
    };

// --- FECHAS Y HORAS ---
DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime hoy() => soloDia(DateTime.now());
String fechaKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
DateTime fechaDeKey(String s) => DateTime.tryParse(s) ?? hoy();

/// Días de diferencia sin que le afecten los cambios de horario.
int diasEntre(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

String diaTexto(DateTime d) {
  final dif = diasEntre(hoy(), d);
  final prefijo = dif == 0 ? 'Hoy, ' : dif == 1 ? 'Mañana, ' : dif == -1 ? 'Ayer, ' : '';
  return '$prefijo${diasLargos[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';
}

/// Lunes de la semana de [d]; la nómina se guarda con esta fecha.
DateTime lunesDe(DateTime d) => soloDia(d).subtract(Duration(days: d.weekday - 1));

/// Domingo con el que empieza la semana de [d] (el Resumen va de domingo a sábado).
DateTime domingoDe(DateTime d) => soloDia(d).subtract(Duration(days: d.weekday % 7));

/// "Del 18 al 24 de octubre" para una semana de 7 días que empieza en [inicio].
String semanaTexto(DateTime inicio) {
  final fin = inicio.add(const Duration(days: 6));
  final mesFin = meses[fin.month - 1];
  return inicio.month == fin.month
      ? 'Del ${inicio.day} al ${fin.day} de $mesFin'
      : 'Del ${inicio.day} de ${meses[inicio.month - 1]} al ${fin.day} de $mesFin';
}

String horaTexto(int minutos) {
  final h = minutos ~/ 60;
  return '${(h % 12) == 0 ? 12 : h % 12}:${(minutos % 60).toString().padLeft(2, '0')}';
}

/// Opciones de "¿Cuánto tarda?", en minutos.
const duraciones = [30, 60, 90, 120, 150, 180, 240, 300, 600];

String duracionTexto(int min) {
  if (min >= 600) return 'Todo el día';
  if (min < 60) return '$min min';
  final h = min ~/ 60, m = min % 60;
  final horas = h == 1 ? '1 hora' : '$h horas';
  return m == 0 ? horas : '$horas y media';
}

String parteDelDia(int hora24) => hora24 < 12 ? 'de la mañana' : hora24 < 19 ? 'de la tarde' : 'de la noche';

String dinero(num n) {
  final f = NumberFormat('#,##0.##', 'en_US');
  return n < 0 ? '−\$${f.format(-n)}' : '\$${f.format(n)}';
}

/// Envuelve una pantalla del encargado con su tema claro.
class EncargadoPage extends StatelessWidget {
  final Widget child;
  const EncargadoPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(data: AppTheme.encargadoTheme, child: child);
}

enum EstiloBoton { normal, primario, exito, peligro, peligroSuave, acentoSuave }

class BotonGrande extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onTap;
  final EstiloBoton estilo;
  final double alto;
  final double fontSize;
  final bool vertical;
  final bool seleccionado;
  final String? subtitulo;
  final double padding;
  final bool ajustarTexto;

  const BotonGrande({
    super.key,
    required this.texto,
    this.icono,
    this.onTap,
    this.estilo = EstiloBoton.normal,
    this.alto = 60,
    this.fontSize = 20,
    this.vertical = false,
    this.seleccionado = false,
    this.subtitulo,
    this.padding = 12,
    this.ajustarTexto = false,
  });

  @override
  Widget build(BuildContext context) {
    var (fondo, frente, borde) = switch (estilo) {
      EstiloBoton.primario => (EC.acentoRelleno, Colors.white, EC.acentoRelleno),
      EstiloBoton.exito => (EC.exito, Colors.white, EC.exito),
      EstiloBoton.peligro => (EC.peligroRelleno, Colors.white, EC.peligroRelleno),
      EstiloBoton.peligroSuave => (EC.fondo, EC.peligroTexto, EC.peligro),
      EstiloBoton.acentoSuave => (EC.fondo, EC.acentoTexto, EC.acento),
      EstiloBoton.normal => (EC.superficie, EC.texto, EC.borde),
    };
    if (seleccionado) {
      (fondo, frente, borde) = (EC.acentoFondo, EC.acentoTexto, EC.acento);
    }
    final iconSize = vertical ? fontSize + 12 : fontSize + 4;
    final textos = <Widget>[
      Text(texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: frente)),
      if (subtitulo != null)
        Text(subtitulo!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: frente == EC.texto ? EC.textoSuave : frente)),
    ];
    final contenido = vertical
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icono != null) Icon(icono, size: iconSize, color: frente),
            if (icono != null) const SizedBox(height: 6),
            ...textos,
          ])
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: ajustarTexto ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (icono != null) Icon(icono, size: iconSize, color: frente),
              if (icono != null) const SizedBox(width: 10),
              // Con ajustarTexto, el FittedBox de abajo encoge todo; sin él, el texto se acomoda en renglones.
              if (ajustarTexto)
                Column(mainAxisSize: MainAxisSize.min, children: textos)
              else
                Flexible(child: Column(mainAxisSize: MainAxisSize.min, children: textos)),
            ],
          );
    return Material(
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borde, width: seleccionado ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: alto),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
            // En botones de alto fijo, el texto se encoge si no cabe (p. ej. con la letra agrandada del celular).
            child: Center(child: ajustarTexto ? FittedBox(fit: BoxFit.scaleDown, child: contenido) : contenido),
          ),
        ),
      ),
    );
  }
}

/// Título grande con flecha de regreso y, opcionalmente, "Paso X de Y" arriba.
class Encabezado extends StatelessWidget {
  final String titulo;
  final String? paso;
  final VoidCallback? onAtras;

  const Encabezado({super.key, required this.titulo, this.paso, this.onAtras});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          if (onAtras != null) ...[
            SizedBox(
              width: 56,
              height: 56,
              child: IconButton.outlined(
                onPressed: onAtras,
                tooltip: 'Atrás',
                iconSize: 28,
                style: IconButton.styleFrom(side: BorderSide(color: EC.borde)),
                icon: Icon(Icons.arrow_back, color: EC.texto),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paso != null) Text(paso!, style: TextStyle(fontSize: 16, color: EC.textoSuave)),
                Text(titulo, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto centrado con flechas grandes a los lados (para cambiar de semana o de mes).
class SelectorConFlechas extends StatelessWidget {
  final String texto;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const SelectorConFlechas({super.key, required this.texto, this.onAnterior, this.onSiguiente});

  Widget _flecha(IconData icono, VoidCallback? onTap, String tooltip) => SizedBox(
        width: 56,
        height: 56,
        child: Opacity(
          opacity: onTap == null ? 0 : 1,
          child: IconButton.outlined(
            onPressed: onTap,
            tooltip: tooltip,
            iconSize: 30,
            style: IconButton.styleFrom(side: BorderSide(color: EC.borde)),
            icon: Icon(icono, color: EC.texto),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _flecha(Icons.chevron_left, onAnterior, 'Anterior'),
        Expanded(
          child: Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
        ),
        _flecha(Icons.chevron_right, onSiguiente, 'Siguiente'),
      ],
    );
  }
}

/// Recuadro gris con una etiqueta pequeña y un monto (como en el Inicio del administrador).
class DatoMonto extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;

  const DatoMonto({super.key, required this.etiqueta, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 15, color: EC.textoSuave)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: color ?? EC.texto)),
          ),
        ],
      ),
    );
  }
}

class TextoError extends StatelessWidget {
  final String? mensaje;
  const TextoError(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) => mensaje == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(mensaje!, style: TextStyle(fontSize: 17, color: EC.peligro, fontWeight: FontWeight.w600)),
        );
}

class CampoGrande extends StatelessWidget {
  final String etiqueta;
  final String? opcional;
  final TextEditingController controller;
  final String? ejemplo;
  final TextInputType? teclado;
  final ValueChanged<String>? onChanged;
  final TextCapitalization mayusculas;
  final List<TextInputFormatter>? formatos;

  const CampoGrande({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.opcional,
    this.ejemplo,
    this.teclado,
    this.onChanged,
    this.mayusculas = TextCapitalization.sentences,
    this.formatos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: etiqueta, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: EC.texto)),
          if (opcional != null) TextSpan(text: '  $opcional', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
        ])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: teclado,
          textCapitalization: mayusculas,
          inputFormatters: formatos,
          onChanged: onChanged,
          style: TextStyle(fontSize: 21, color: EC.texto),
          decoration: InputDecoration(hintText: ejemplo),
        ),
      ],
    );
  }
}

/// Monto grande + teclado numérico propio (sin teclado del sistema).
class TecladoMonto extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const TecladoMonto({super.key, required this.valor, required this.onChanged});

  void _tecla(String k) {
    if (k == '<') {
      onChanged(valor.isEmpty ? '' : valor.substring(0, valor.length - 1));
    } else {
      final nuevo = (valor + k).replaceFirst(RegExp(r'^0+'), '');
      if (nuevo.length <= 7) onChanged(nuevo);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teclas = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: EC.bordeFuerte, width: 2))),
          child: Text(dinero(int.tryParse(valor) ?? 0),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: EC.texto)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            for (final k in teclas)
              if (k.isEmpty)
                const SizedBox.shrink()
              else
                BotonGrande(
                  texto: k == '<' ? '' : k,
                  icono: k == '<' ? Icons.backspace_outlined : null,
                  fontSize: 28,
                  alto: 56,
                  onTap: () => _tecla(k),
                ),
          ],
        ),
      ],
    );
  }
}

/// Calendario de un mes con flechas grandes. Marca con puntos los días que tienen pendientes.
class CalendarioMes extends StatefulWidget {
  final DateTime? seleccionado;
  final ValueChanged<DateTime> onDia;
  final int Function(DateTime dia) pendientes;
  final bool permitirPasado;

  const CalendarioMes({
    super.key,
    required this.onDia,
    required this.pendientes,
    this.seleccionado,
    this.permitirPasado = true,
  });

  @override
  State<CalendarioMes> createState() => _CalendarioMesState();
}

class _CalendarioMesState extends State<CalendarioMes> {
  late DateTime _mes;
  String? _error;

  @override
  void initState() {
    super.initState();
    final base = widget.seleccionado ?? hoy();
    _mes = DateTime(base.year, base.month);
  }

  void _mover(int delta) => setState(() {
        _mes = DateTime(_mes.year, _mes.month + delta);
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final h = hoy();
    final primero = DateTime(_mes.year, _mes.month, 1);
    final vacios = primero.weekday - 1; // la semana empieza en lunes
    final totalDias = DateTime(_mes.year, _mes.month + 1, 0).day;
    final puedeAtras = widget.permitirPasado || _mes.isAfter(DateTime(h.year, h.month));
    final nombreMes = meses[_mes.month - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _flecha(Icons.chevron_left, puedeAtras ? () => _mover(-1) : null, 'Mes anterior'),
            Expanded(
              child: Text('${nombreMes[0].toUpperCase()}${nombreMes.substring(1)} ${_mes.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: EC.texto)),
            ),
            _flecha(Icons.chevron_right, () => _mover(1), 'Mes siguiente'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(['L', 'M', 'M', 'J', 'V', 'S', 'D'][i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: i == 6 ? EC.peligro : EC.textoSuave)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 0.82,
          children: [
            for (var i = 0; i < vacios; i++) const SizedBox.shrink(),
            for (var d = 1; d <= totalDias; d++) _celda(DateTime(_mes.year, _mes.month, d), h),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(TextSpan(children: [
          TextSpan(text: '●  ', style: TextStyle(color: EC.acento, fontSize: 15)),
          TextSpan(text: 'trabajos pendientes ese día', style: TextStyle(color: EC.textoSuave, fontSize: 16)),
        ])),
        TextoError(_error),
      ],
    );
  }

  Widget _flecha(IconData icono, VoidCallback? onTap, String tooltip) => SizedBox(
        width: 56,
        height: 56,
        child: Opacity(
          opacity: onTap == null ? 0 : 1,
          child: IconButton.outlined(
            onPressed: onTap,
            tooltip: tooltip,
            iconSize: 30,
            style: IconButton.styleFrom(side: BorderSide(color: EC.borde)),
            icon: Icon(icono, color: EC.texto),
          ),
        ),
      );

  Widget _celda(DateTime dia, DateTime h) {
    final pasado = dia.isBefore(h);
    final esHoy = dia == h;
    final sel = widget.seleccionado != null && soloDia(widget.seleccionado!) == dia;
    final domingo = dia.weekday == DateTime.sunday;
    final n = widget.pendientes(dia);
    final colorTexto = sel
        ? EC.acentoTexto
        : pasado
            ? EC.textoTenue
            : domingo
                ? EC.peligro
                : EC.texto;
    return Material(
      color: sel ? EC.acentoFondo : pasado ? Colors.transparent : EC.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: sel ? EC.acento : esHoy ? EC.bordeFuerte : EC.borde,
          width: sel || esHoy ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (pasado && !widget.permitirPasado) {
            setState(() => _error = 'Ese día ya pasó. Elige hoy o un día después.');
            return;
          }
          setState(() => _error = null);
          widget.onDia(dia);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${dia.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorTexto)),
            SizedBox(
              height: 12,
              child: Text(n > 0 ? '●' * (n > 3 ? 3 : n) : '',
                  style: TextStyle(fontSize: 9, color: EC.acento, height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de la luna (o el sol en modo oscuro) que abre "Aspecto de la app".
class BotonAspecto extends StatelessWidget {
  const BotonAspecto({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.outlined(
        tooltip: 'Aspecto de la app',
        onPressed: () => mostrarAspecto(context),
        style: IconButton.styleFrom(side: BorderSide(color: EC.borde)),
        icon: Icon(EC.oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: EC.textoSuave),
      ),
    );
  }
}

/// Hoja "Aspecto de la app": Claro u Oscuro.
void mostrarAspecto(BuildContext context) {
  final servicio = context.read<AspectoService>();
  showModalBottomSheet(
    context: context,
    backgroundColor: EC.fondo,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      Widget opcion(String valor, IconData icono, String titulo, String detalle) {
        final elegida = servicio.aspecto == valor;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: elegida ? EC.acentoFondo : EC.superficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: elegida ? EC.acento : EC.borde, width: elegida ? 2 : 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(ctx).pop();
                servicio.cambiar(valor);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  Icon(icono, size: 30, color: elegida ? EC.acentoTexto : EC.texto),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(titulo,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: elegida ? EC.acentoTexto : EC.texto)),
                      Text(detalle, style: TextStyle(fontSize: 16, color: elegida ? EC.acentoTexto : EC.textoSuave)),
                    ]),
                  ),
                  if (elegida) Icon(Icons.check, size: 28, color: EC.acentoTexto),
                ]),
              ),
            ),
          ),
        );
      }

      return EncargadoPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Aspecto de la app', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
              Text('Se guarda en este celular.', style: TextStyle(fontSize: 17, color: EC.textoSuave)),
              const SizedBox(height: 16),
              opcion('claro', Icons.light_mode_outlined, 'Claro', 'Fondo blanco'),
              opcion('oscuro', Icons.dark_mode_outlined, 'Oscuro', 'Fondo oscuro, cansa menos la vista de noche'),
            ]),
          ),
        ),
      );
    },
  );
}

/// Pantalla de confirmación con palomita. Ofrece corregir lo que se acaba de
/// guardar (abre los datos ya escritos) o, si no hay forma de corregir, deshacer.
class PantallaListo extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final VoidCallback? onDeshacer;

  /// Abre de nuevo lo guardado para cambiar datos; recibe el contexto de esta pantalla.
  final void Function(BuildContext context)? onCorregir;

  const PantallaListo({super.key, required this.titulo, required this.mensaje, this.onDeshacer, this.onCorregir});

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(color: EC.exitoFondo, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 76, color: EC.exitoTexto),
                  ),
                ),
                const SizedBox(height: 18),
                Text(titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: EC.texto)),
                const SizedBox(height: 8),
                Text(mensaje, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, color: EC.textoSuave, height: 1.35)),
                const SizedBox(height: 32),
                BotonGrande(texto: 'Listo', estilo: EstiloBoton.primario, onTap: () => Navigator.of(context).pop()),
                if (onCorregir != null) ...[
                  const SizedBox(height: 12),
                  BotonGrande(
                    texto: 'Me equivoqué, corregir',
                    icono: Icons.edit_outlined,
                    fontSize: 18,
                    alto: 56,
                    onTap: () => onCorregir!(context),
                  ),
                ] else if (onDeshacer != null) ...[
                  const SizedBox(height: 12),
                  BotonGrande(
                    texto: 'Me equivoqué, deshacer',
                    icono: Icons.undo,
                    fontSize: 18,
                    alto: 54,
                    onTap: () {
                      onDeshacer!();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla roja de "¿Seguro que quieres borrar?".
class PantallaBorrar extends StatelessWidget {
  final String pregunta;
  final String detalle;
  final VoidCallback onBorrar;

  const PantallaBorrar({super.key, required this.pregunta, required this.detalle, required this.onBorrar});

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(color: EC.peligroFondo, shape: BoxShape.circle),
                    child: Icon(Icons.delete_outline, size: 58, color: EC.peligroTexto),
                  ),
                ),
                const SizedBox(height: 18),
                Text(pregunta,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
                const SizedBox(height: 8),
                Text(detalle, textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: EC.textoSuave, height: 1.35)),
                const SizedBox(height: 32),
                BotonGrande(texto: 'Sí, borrar', estilo: EstiloBoton.peligro, onTap: onBorrar),
                const SizedBox(height: 12),
                BotonGrande(texto: 'No, dejarlo', onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
