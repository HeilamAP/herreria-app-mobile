import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/visita_agenda.dart';
import '../../services/app_engine_service.dart';
import 'ui.dart';

/// Agendar (o cambiar) un trabajo en pasos, una pregunta por pantalla:
/// cliente → tipo → dirección → cobro aproximado → día → hora → minutos → cuánto tarda → confirmar.
/// Si se llega desde un hueco del horario ([minutoInicial] dado), el día y la hora ya vienen elegidos.
class AgendarScreen extends StatefulWidget {
  final String equipoId;
  final VisitaAgenda? existente;
  final bool soloCambiarFecha;
  final bool elegirEquipo;
  final DateTime? diaInicial;
  final int? minutoInicial; // minutos desde medianoche
  final ValueChanged<DateTime>? onDiaGuardado;

  const AgendarScreen({
    super.key,
    required this.equipoId,
    this.existente,
    this.soloCambiarFecha = false,
    this.elegirEquipo = false,
    this.diaInicial,
    this.minutoInicial,
    this.onDiaGuardado,
  });

  @override
  State<AgendarScreen> createState() => _AgendarScreenState();
}

enum _Paso { cliente, tipo, lugar, estimado, dia, hora, minutos, duracion, confirmar }

class _AgendarScreenState extends State<AgendarScreen> {
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();
  late _Paso _paso;
  String _tipo = '';
  String _estimado = '';
  DateTime? _dia;
  int? _hora; // 0-23
  int? _minuto;
  int _duracion = 60;
  String _periodo = 'manana';
  late String _equipo;
  String? _error;

  bool get _editando => widget.existente != null;
  bool get _horaYaElegida => widget.minutoInicial != null && !_editando;

  /// Pasos que se recorren, en orden. "Cambiar día u hora" solo mueve la fecha.
  List<_Paso> get _flujo => widget.soloCambiarFecha
      ? const [_Paso.dia, _Paso.hora, _Paso.minutos, _Paso.confirmar]
      : [
          _Paso.cliente,
          _Paso.tipo,
          _Paso.lugar,
          _Paso.estimado,
          if (!_horaYaElegida) ...[_Paso.dia, _Paso.hora, _Paso.minutos],
          _Paso.duracion,
          _Paso.confirmar,
        ];

  /// Hora y minutos cuentan como un solo paso para el "Paso X de Y".
  List<_Paso> get _pasosNumerados => _flujo.where((p) => p != _Paso.minutos && p != _Paso.confirmar).toList();

  @override
  void initState() {
    super.initState();
    _equipo = widget.equipoId;
    _dia = widget.diaInicial;
    if (widget.minutoInicial != null) {
      _hora = widget.minutoInicial! ~/ 60;
      _minuto = widget.minutoInicial! % 60;
    }
    final e = widget.existente;
    if (e != null) {
      _cliente.text = e.cliente;
      _telefono.text = e.telefono;
      _direccion.text = e.direccion;
      _notas.text = e.notas;
      _tipo = e.tipo;
      _estimado = e.montoEstimado > 0 ? e.montoEstimado.round().toString() : '';
      _dia = fechaDeKey(e.fecha);
      _hora = e.minutosDelDia ~/ 60;
      _minuto = e.minutosDelDia % 60;
      _duracion = e.duracionMin;
      _equipo = e.equipoId;
    }
    _paso = _flujo.first;
  }

  @override
  void dispose() {
    _cliente.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _ir(_Paso p) => setState(() {
        _paso = p;
        _error = null;
        if (p == _Paso.hora && _hora != null) {
          _periodo = _hora! < 12 ? 'manana' : _hora! < 19 ? 'tarde' : 'noche';
        }
      });

  void _avanzar() {
    final i = _flujo.indexOf(_paso);
    if (i >= 0 && i + 1 < _flujo.length) _ir(_flujo[i + 1]);
  }

  /// Avanza tras una pausa corta, para que se vea marcado lo que se tocó.
  void _avanzarPronto([int ms = 200]) => Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) _avanzar();
      });

  void _atras() {
    final i = _flujo.indexOf(_paso);
    if (i <= 0) {
      Navigator.of(context).pop();
    } else {
      _ir(_flujo[i - 1]);
    }
  }

  String? _textoPaso(_Paso p) {
    if (widget.soloCambiarFecha) return null;
    if (_editando) return 'Cambiando datos';
    final numerados = _pasosNumerados;
    final n = numerados.indexOf(p == _Paso.minutos ? _Paso.hora : p) + 1;
    return 'Paso $n de ${numerados.length}';
  }

  void _guardar() {
    final engine = context.read<AppEngineService>();
    final previo = widget.existente?.copia();
    final v = widget.existente?.copia() ??
        VisitaAgenda(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cliente: '',
          fecha: '',
          tipo: '',
          direccion: '',
          telefono: '',
          notas: '',
          estado: 'pendiente',
        );
    v
      ..cliente = _cliente.text.trim()
      ..telefono = _telefono.text.trim()
      ..direccion = _direccion.text.trim()
      ..notas = _notas.text.trim()
      ..tipo = _tipo
      ..montoEstimado = double.tryParse(_estimado) ?? 0
      ..fecha = fechaKey(_dia!)
      ..hora = VisitaAgenda.horaDeMinutos(_hora! * 60 + _minuto!)
      ..duracionMin = _duracion
      ..equipoId = _equipo;
    engine.saveVisitaAgenda(v);
    widget.onDiaGuardado?.call(_dia!);

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PantallaListo(
        titulo: _editando ? 'Cambios guardados' : 'Agendado',
        mensaje: '${v.cliente}\n${diaTexto(_dia!)}\n${horaTexto(_hora! * 60 + _minuto!)} ${parteDelDia(_hora!)}',
        onDeshacer: () {
          if (previo != null) {
            engine.saveVisitaAgenda(previo);
            widget.onDiaGuardado?.call(fechaDeKey(previo.fecha));
          } else {
            engine.deleteVisitaAgenda(v.id);
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _atras();
        },
        child: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: switch (_paso) {
                _Paso.cliente => _pasoCliente(),
                _Paso.tipo => _pasoTipo(),
                _Paso.lugar => _pasoLugar(),
                _Paso.estimado => _pasoEstimado(),
                _Paso.dia => _pasoDia(),
                _Paso.hora => _pasoHora(),
                _Paso.minutos => _pasoMinutos(),
                _Paso.duracion => _pasoDuracion(),
                _Paso.confirmar => _pasoConfirmar(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _siguiente(VoidCallback onTap, {String texto = 'Siguiente'}) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: BotonGrande(texto: texto, icono: Icons.arrow_forward, estilo: EstiloBoton.primario, onTap: onTap),
      );

  List<Widget> _pasoCliente() => [
        Encabezado(titulo: '¿Para quién es?', paso: _textoPaso(_Paso.cliente), onAtras: _atras),
        const SizedBox(height: 16),
        CampoGrande(
          etiqueta: 'Nombre del cliente',
          controller: _cliente,
          ejemplo: 'Juan Canché',
          mayusculas: TextCapitalization.words,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        TextoError(_error),
        const SizedBox(height: 18),
        CampoGrande(
          etiqueta: 'Teléfono',
          opcional: '(si lo tienes)',
          controller: _telefono,
          ejemplo: '999 123 4567',
          teclado: TextInputType.phone,
        ),
        _siguiente(() {
          if (_cliente.text.trim().isEmpty) {
            setState(() => _error = 'Escribe el nombre del cliente');
            return;
          }
          _avanzar();
        }),
      ];

  List<Widget> _pasoTipo() => [
        Encabezado(titulo: '¿Qué es?', paso: _textoPaso(_Paso.tipo), onAtras: _atras),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final t in tiposTrabajo)
              BotonGrande(
                texto: t.$1,
                icono: t.$2,
                vertical: true,
                fontSize: 18,
                seleccionado: _tipo == t.$1,
                onTap: () {
                  setState(() => _tipo = t.$1);
                  _avanzarPronto(180);
                },
              ),
          ],
        ),
      ];

  List<Widget> _pasoLugar() {
    final esVenta = _tipo.toLowerCase() == 'venta';
    return [
      Encabezado(titulo: '¿Dónde es?', paso: _textoPaso(_Paso.lugar), onAtras: _atras),
      const SizedBox(height: 16),
      CampoGrande(etiqueta: 'Dirección', controller: _direccion, ejemplo: 'Calle 21 #300 x 20 y 22'),
      const SizedBox(height: 6),
      const Text('Con la dirección, el botón "Cómo llegar" abre el mapa.', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
      const SizedBox(height: 18),
      CampoGrande(
        etiqueta: esVenta ? '¿Qué vas a vender?' : 'Notas',
        opcional: '(opcional)',
        controller: _notas,
        ejemplo: esVenta ? '2 controles remotos' : 'Llevar soldadora',
      ),
      _siguiente(_avanzar),
    ];
  }

  List<Widget> _pasoEstimado() => [
        Encabezado(titulo: '¿Cuánto vas a cobrar?', paso: _textoPaso(_Paso.estimado), onAtras: _atras),
        const Text('Aproximado. Lo puedes cambiar al cobrar.', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 12),
        TecladoMonto(valor: _estimado, onChanged: (v) => setState(() => _estimado = v)),
        _siguiente(_avanzar),
        const SizedBox(height: 10),
        BotonGrande(
          texto: 'No lo sé todavía',
          fontSize: 18,
          alto: 54,
          onTap: () {
            _estimado = '';
            _avanzar();
          },
        ),
      ];

  List<Widget> _pasoDia() {
    final engine = context.read<AppEngineService>();
    final h = hoy();
    void elegir(DateTime d) {
      setState(() => _dia = d);
      _avanzarPronto(180);
    }

    return [
      Encabezado(titulo: '¿Qué día?', paso: _textoPaso(_Paso.dia), onAtras: _atras),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: BotonGrande(texto: 'Hoy', alto: 58, seleccionado: _dia == h, onTap: () => elegir(h))),
        const SizedBox(width: 10),
        Expanded(
          child: BotonGrande(
            texto: 'Mañana',
            alto: 58,
            seleccionado: _dia == h.add(const Duration(days: 1)),
            onTap: () => elegir(h.add(const Duration(days: 1))),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      const Text('O busca el día en el calendario:', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
      const SizedBox(height: 10),
      CalendarioMes(
        seleccionado: _dia,
        permitirPasado: false,
        pendientes: (d) => engine.pendientesEn(_equipo, fechaKey(d)),
        onDia: elegir,
      ),
    ];
  }

  Widget _pantallaHora() {
    final hh = _hora;
    final mm = _paso == _Paso.hora ? null : _minuto;
    const tenue = TextStyle(color: EC.textoTenue);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: hh == null ? '–' : '${hh % 12 == 0 ? 12 : hh % 12}', style: hh == null ? tenue : null),
            const TextSpan(text: ':', style: tenue),
            TextSpan(text: mm == null ? '– –' : mm.toString().padLeft(2, '0'), style: mm == null ? tenue : null),
          ]),
          style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w700, color: EC.texto, height: 1),
        ),
        const SizedBox(height: 6),
        Text(hh == null ? 'Elige la hora' : parteDelDia(hh), style: const TextStyle(fontSize: 19, color: EC.textoSuave)),
      ]),
    );
  }

  List<Widget> _pasoHora() {
    const periodos = [
      ('manana', 'Mañana', Icons.wb_sunny_outlined, 6, 11),
      ('tarde', 'Tarde', Icons.wb_twilight, 12, 18),
      ('noche', 'Noche', Icons.dark_mode_outlined, 19, 21),
    ];
    final p = periodos.firstWhere((x) => x.$1 == _periodo);
    return [
      Encabezado(
        titulo: '¿A qué hora?',
        paso: widget.soloCambiarFecha ? diaTexto(_dia!) : _textoPaso(_Paso.hora),
        onAtras: _atras,
      ),
      const SizedBox(height: 12),
      _pantallaHora(),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          for (final x in periodos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: _periodo == x.$1 ? EC.fondo : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _periodo == x.$1 ? EC.bordeFuerte : Colors.transparent),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _periodo = x.$1),
                    child: SizedBox(
                      height: 62,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(x.$3, size: 24, color: _periodo == x.$1 ? EC.texto : EC.textoSuave),
                        Text(x.$2,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: _periodo == x.$1 ? FontWeight.w700 : FontWeight.w400,
                              color: _periodo == x.$1 ? EC.texto : EC.textoSuave,
                            )),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          for (var h = p.$4; h <= p.$5; h++)
            BotonGrande(
              texto: '${h % 12 == 0 ? 12 : h % 12}',
              fontSize: 32,
              seleccionado: _hora == h,
              onTap: () {
                final elegida = h;
                setState(() {
                  // Al cambiar la hora, los minutos se vuelven a elegir.
                  if (_hora != elegida) _minuto = null;
                  _hora = elegida;
                });
                _avanzarPronto(200);
              },
            ),
        ],
      ),
    ];
  }

  List<Widget> _pasoMinutos() => [
        Encabezado(
          titulo: '¿Y los minutos?',
          paso: widget.soloCambiarFecha ? diaTexto(_dia!) : _textoPaso(_Paso.minutos),
          onAtras: _atras,
        ),
        const SizedBox(height: 12),
        _pantallaHora(),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (var m = 0; m < 60; m += 5)
              BotonGrande(
                texto: ':${m.toString().padLeft(2, '0')}',
                fontSize: 28,
                seleccionado: _minuto == m,
                onTap: () {
                  final elegido = m;
                  setState(() => _minuto = elegido);
                  _avanzarPronto(220);
                },
              ),
          ],
        ),
      ];

  List<Widget> _pasoDuracion() {
    final inicio = _hora! * 60 + _minuto!;
    return [
      Encabezado(titulo: '¿Cuánto tarda?', paso: _textoPaso(_Paso.duracion), onAtras: _atras),
      Text('Empieza a las ${horaTexto(inicio)} ${parteDelDia(_hora!)}', style: const TextStyle(fontSize: 18, color: EC.textoSuave)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          for (final d in duraciones)
            BotonGrande(
              texto: duracionTexto(d),
              subtitulo: d >= 600 ? null : 'hasta las ${horaTexto(inicio + d)}',
              fontSize: 20,
              padding: 6,
              seleccionado: _duracion == d,
              onTap: () {
                setState(() => _duracion = d);
                _avanzarPronto(200);
              },
            ),
        ],
      ),
    ];
  }

  List<Widget> _pasoConfirmar() {
    Widget linea(IconData i, String t, {Color color = EC.texto}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 22, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: TextStyle(fontSize: 19, color: color))),
          ]),
        );
    final minutos = _hora! * 60 + _minuto!;
    final estimado = double.tryParse(_estimado) ?? 0;
    return [
      Encabezado(titulo: '¿Está bien así?', onAtras: _atras),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: EC.bordeFuerte)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_cliente.text.trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: EC.texto)),
            linea(iconoDeTipo(_tipo), '$_tipo${_notas.text.trim().isNotEmpty ? ' · ${_notas.text.trim()}' : ''}'),
            linea(Icons.calendar_today_outlined, diaTexto(_dia!)),
            linea(Icons.schedule, '${horaTexto(minutos)} ${parteDelDia(_hora!)}'),
            linea(Icons.timelapse, _duracion >= 600 ? 'Todo el día' : 'Tarda ${duracionTexto(_duracion)} (hasta las ${horaTexto(minutos + _duracion)})'),
            linea(Icons.payments_outlined, estimado > 0 ? 'Cobrar aprox. ${dinero(estimado)}' : 'Cobro por definir'),
            linea(Icons.place_outlined, _direccion.text.trim().isEmpty ? 'Sin dirección' : _direccion.text.trim(), color: EC.textoSuave),
            if (_telefono.text.trim().isNotEmpty) linea(Icons.phone_outlined, _telefono.text.trim(), color: EC.textoSuave),
            if (!widget.elegirEquipo) linea(Icons.groups_outlined, nombreEquipo(_equipo), color: EC.textoSuave),
          ],
        ),
      ),
      if (widget.elegirEquipo) ...[
        const SizedBox(height: 16),
        const Text('¿Qué equipo lo hace?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: EC.texto)),
        const SizedBox(height: 8),
        Row(children: [
          for (final e in ['equipo1', 'equipo2']) ...[
            Expanded(
              child: BotonGrande(
                texto: nombreEquipo(e),
                subtitulo: context
                    .read<AppEngineService>()
                    .data
                    .usuarios
                    .where((u) => !u.isAdmin && u.equipoId == e)
                    .map((u) => u.nombre)
                    .firstOrNull,
                seleccionado: _equipo == e,
                alto: 64,
                onTap: () => setState(() => _equipo = e),
              ),
            ),
            if (e == 'equipo1') const SizedBox(width: 10),
          ],
        ]),
      ],
      const SizedBox(height: 24),
      BotonGrande(
        texto: _editando ? 'Guardar cambios' : 'Agendar',
        icono: Icons.check,
        estilo: EstiloBoton.exito,
        onTap: _guardar,
      ),
      if (!_editando) ...[
        const SizedBox(height: 10),
        BotonGrande(texto: 'Cambiar algo', fontSize: 18, alto: 54, onTap: () => _ir(_Paso.cliente)),
      ],
    ];
  }
}
