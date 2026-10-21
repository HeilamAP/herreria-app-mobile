import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/visita_agenda.dart';
import '../../services/app_engine_service.dart';
import '../../services/foto_store.dart';
import 'ui.dart';

/// Miniatura cuadrada de una foto guardada. Si la foto ya no existe, muestra un aviso.
class FotoMiniatura extends StatelessWidget {
  final String id;
  final VoidCallback? onTap;
  final double radio;

  const FotoMiniatura({super.key, required this.id, this.onTap, this.radio = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Material(
        color: EC.superficie,
        child: InkWell(
          onTap: onTap,
          child: FutureBuilder<Uint8List?>(
            future: leerFoto(id),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const SizedBox.expand();
              final bytes = snap.data;
              if (bytes == null) {
                return const Center(child: Icon(Icons.image_not_supported_outlined, color: EC.textoTenue, size: 30));
              }
              return Ink.image(image: MemoryImage(bytes), fit: BoxFit.cover, child: const SizedBox.expand());
            },
          ),
        ),
      ),
    );
  }
}

/// Fotos en grande, una por pantalla; se desliza para pasar a la siguiente.
class FotoVisorScreen extends StatefulWidget {
  final List<String> fotos;
  final int inicial;

  const FotoVisorScreen({super.key, required this.fotos, this.inicial = 0});

  @override
  State<FotoVisorScreen> createState() => _FotoVisorScreenState();
}

class _FotoVisorScreenState extends State<FotoVisorScreen> {
  late final _pagina = PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: Text('Foto ${_actual + 1} de ${widget.fotos.length}',
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 52),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.close),
                label: const Text('Cerrar'),
              ),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pagina,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (_, i) => FutureBuilder<Uint8List?>(
                future: leerFoto(widget.fotos[i]),
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null) {
                    return Center(
                      child: snap.connectionState == ConnectionState.done
                          ? const Text('Esta foto ya no está en el teléfono', style: TextStyle(fontSize: 18, color: Colors.white70))
                          : const CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return InteractiveViewer(maxScale: 4, child: Center(child: Image.memory(bytes, fit: BoxFit.contain)));
                },
              ),
            ),
          ),
          if (widget.fotos.length > 1)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Desliza para ver la siguiente', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ),
        ]),
      ),
    );
  }
}

/// Último paso opcional al terminar de cobrar: agregar fotos o una nota, o terminar.
class PreguntaFotosScreen extends StatelessWidget {
  final String trabajoId;
  final void Function(BuildContext context) onTerminar;

  const PreguntaFotosScreen({super.key, required this.trabajoId, required this.onTerminar});

  @override
  Widget build(BuildContext context) {
    void abrir({required bool camara}) => Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => FotosNotaScreen(
            trabajoId: trabajoId,
            abrirCamara: camara,
            enfocarNota: !camara,
            onTerminar: onTerminar,
          ),
        ));

    return EncargadoPage(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onTerminar(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const SizedBox(height: 6),
                const Text('Último paso (opcional)', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
                const Text('¿Quieres agregar fotos o una nota?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto, height: 1.2)),
                const SizedBox(height: 4),
                const Text('Sirve para recordar cómo quedó el trabajo.', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
                const SizedBox(height: 20),
                BotonGrande(texto: 'Tomar fotos', icono: Icons.photo_camera_outlined, vertical: true, alto: 110, fontSize: 22,
                    onTap: () => abrir(camara: true)),
                const SizedBox(height: 12),
                BotonGrande(texto: 'Escribir nota', icono: Icons.edit_note, vertical: true, alto: 110, fontSize: 22,
                    onTap: () => abrir(camara: false)),
                const SizedBox(height: 24),
                BotonGrande(texto: 'Terminar sin nada', estilo: EstiloBoton.primario, onTap: () => onTerminar(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fotos y nota final de un trabajo. Cada foto se guarda en cuanto se toma;
/// la nota se guarda al salir de la pantalla.
class FotosNotaScreen extends StatefulWidget {
  final String trabajoId;
  final bool abrirCamara;
  final bool enfocarNota;
  final void Function(BuildContext context)? onTerminar;

  const FotosNotaScreen({
    super.key,
    required this.trabajoId,
    this.abrirCamara = false,
    this.enfocarNota = false,
    this.onTerminar,
  });

  @override
  State<FotosNotaScreen> createState() => _FotosNotaScreenState();
}

class _FotosNotaScreenState extends State<FotosNotaScreen> {
  final _nota = TextEditingController();
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _nota.text = context.read<AppEngineService>().visitaPorId(widget.trabajoId)?.notaFinal ?? '';
    if (widget.abrirCamara) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _agregar(ImageSource.camera));
    }
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  void _aviso(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontSize: 18)), behavior: SnackBarBehavior.floating),
      );

  Future<void> _agregar(ImageSource origen) async {
    final engine = context.read<AppEngineService>();
    final v = engine.visitaPorId(widget.trabajoId);
    if (v == null || _ocupado) return;
    if (v.fotos.length >= VisitaAgenda.maxFotos) {
      _aviso('Ya tiene ${VisitaAgenda.maxFotos} fotos. Quita una para agregar otra.');
      return;
    }
    setState(() => _ocupado = true);
    try {
      // Se reduce el tamaño para que cada foto pese poco (unos 200 KB).
      final archivo = await ImagePicker().pickImage(source: origen, maxWidth: 1600, maxHeight: 1600, imageQuality: 70);
      if (archivo == null) return;
      final id = await guardarFoto(await archivo.readAsBytes());
      final actual = engine.visitaPorId(widget.trabajoId);
      if (actual != null) engine.actualizarNotaYFotos(actual.id, fotos: [...actual.fotos, id]);
    } catch (_) {
      if (mounted) {
        _aviso(origen == ImageSource.camera ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _quitar(VisitaAgenda v, String id) async {
    final quitar = await showDialog<bool>(
      context: context,
      builder: (ctx) => EncargadoPage(
        child: AlertDialog(
          title: const Text('¿Quitar esta foto?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          content: SizedBox(width: 220, height: 220, child: FotoMiniatura(id: id)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              BotonGrande(texto: 'Sí, quitar', estilo: EstiloBoton.peligro, onTap: () => Navigator.of(ctx).pop(true)),
              const SizedBox(height: 10),
              BotonGrande(texto: 'No, dejarla', onTap: () => Navigator.of(ctx).pop(false)),
            ]),
          ],
        ),
      ),
    );
    if (quitar != true || !mounted) return;
    context.read<AppEngineService>().actualizarNotaYFotos(v.id, fotos: v.fotos.where((f) => f != id).toList());
    await borrarFoto(id);
  }

  void _terminar() {
    final engine = context.read<AppEngineService>();
    final v = engine.visitaPorId(widget.trabajoId);
    if (v != null && v.notaFinal != _nota.text.trim()) {
      engine.actualizarNotaYFotos(v.id, notaFinal: _nota.text.trim());
    }
    if (widget.onTerminar != null) {
      widget.onTerminar!(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.watch<AppEngineService>().visitaPorId(widget.trabajoId);
    if (v == null) {
      return const EncargadoPage(child: Scaffold(body: Center(child: Text('Este trabajo ya no existe'))));
    }
    final lleno = v.fotos.length >= VisitaAgenda.maxFotos;

    return EncargadoPage(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _terminar();
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Encabezado(titulo: 'Fotos y nota', paso: '${v.cliente} · ${v.tipo}', onAtras: _terminar),
                    const SizedBox(height: 12),
                    if (v.fotos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                        child: const Text('Todavía no hay fotos', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: EC.textoSuave)),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (var i = 0; i < v.fotos.length; i++)
                            Stack(fit: StackFit.expand, children: [
                              FotoMiniatura(
                                id: v.fotos[i],
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => FotoVisorScreen(fotos: v.fotos, inicial: i),
                                )),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: 'Quitar foto',
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                                    onPressed: () => _quitar(v, v.fotos[i]),
                                  ),
                                ),
                              ),
                            ]),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text('${v.fotos.length} de ${VisitaAgenda.maxFotos} fotos', style: const TextStyle(fontSize: 15, color: EC.textoSuave)),
                    const SizedBox(height: 10),
                    if (_ocupado)
                      const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
                    else
                      Row(children: [
                        Expanded(
                          child: BotonGrande(
                            texto: 'Tomar foto',
                            icono: Icons.photo_camera_outlined,
                            vertical: true,
                            fontSize: 18,
                            alto: 76,
                            estilo: lleno ? EstiloBoton.normal : EstiloBoton.acentoSuave,
                            onTap: () => _agregar(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BotonGrande(
                            texto: 'De la galería',
                            icono: Icons.photo_library_outlined,
                            vertical: true,
                            fontSize: 18,
                            alto: 76,
                            onTap: () => _agregar(ImageSource.gallery),
                          ),
                        ),
                      ]),
                    const SizedBox(height: 20),
                    const Text('Nota', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nota,
                      autofocus: widget.enfocarNota,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 20, color: EC.texto),
                      decoration: const InputDecoration(hintText: 'Ej. Se cambió la tarjeta del motor. Volver en 6 meses.'),
                    ),
                    const SizedBox(height: 24),
                    BotonGrande(texto: 'Guardar', icono: Icons.check, estilo: EstiloBoton.exito, onTap: _terminar),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recuadro "Notas y fotos" para la tarjeta del trabajo: la nota final y hasta
/// 3 miniaturas (con "+N" si hay más). Al tocarlo se abre la pantalla completa.
class NotasYFotosResumen extends StatelessWidget {
  final VisitaAgenda trabajo;
  final VoidCallback onAbrir;

  const NotasYFotosResumen({super.key, required this.trabajo, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final t = trabajo;
    final mostrar = t.fotos.take(t.fotos.length > 4 ? 3 : 4).toList();
    final extra = t.fotos.length - mostrar.length;
    return Material(
      color: EC.fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: EC.borde)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Row(children: [
              Icon(Icons.edit_note, size: 22, color: EC.textoSuave),
              SizedBox(width: 6),
              Expanded(child: Text('Notas y fotos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EC.textoSuave))),
              Icon(Icons.chevron_right, color: EC.textoSuave),
            ]),
            if (t.notaFinal.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.notaFinal, style: const TextStyle(fontSize: 18, color: EC.texto)),
            ],
            if (t.fotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                for (final f in mostrar) ...[
                  Expanded(child: AspectRatio(aspectRatio: 1, child: FotoMiniatura(id: f, radio: 8))),
                  const SizedBox(width: 6),
                ],
                if (extra > 0)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text('+$extra', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EC.textoSuave)),
                      ),
                    ),
                  ),
                for (var i = mostrar.length + (extra > 0 ? 1 : 0); i < 4; i++) const Expanded(child: SizedBox()),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
