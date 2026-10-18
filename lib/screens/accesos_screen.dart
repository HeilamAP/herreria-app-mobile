import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'encargado/ui.dart';

/// Para el administrador: borrar el PIN de un encargado y cambiar su propia contraseña.
class AccesosScreen extends StatefulWidget {
  const AccesosScreen({super.key});

  @override
  State<AccesosScreen> createState() => _AccesosScreenState();
}

class _AccesosScreenState extends State<AccesosScreen> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  void _aviso(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontSize: 17)), behavior: SnackBarBehavior.floating),
      );

  void _cambiarPassword() {
    final auth = context.read<AuthService>();
    if (_nueva.text.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_nueva.text != _repetir.text) {
      setState(() => _error = 'Las dos contraseñas nuevas no son iguales.');
      return;
    }
    if (!auth.cambiarPassword(_actual.text, _nueva.text)) {
      setState(() => _error = 'La contraseña actual no es correcta.');
      return;
    }
    _actual.clear();
    _nueva.clear();
    _repetir.clear();
    setState(() => _error = null);
    _aviso('Contraseña cambiada');
  }

  Widget _campo(String etiqueta, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          obscureText: true,
          style: const TextStyle(fontSize: 19),
          decoration: InputDecoration(labelText: etiqueta),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Encabezado(titulo: 'Accesos', onAtras: () => Navigator.of(context).pop()),
                  const SizedBox(height: 12),
                  const Text('PIN de los encargados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
                  const Text('Si alguien olvida su PIN, bórralo. La próxima vez que entre, creará uno nuevo.',
                      style: TextStyle(fontSize: 16, color: EC.textoSuave)),
                  const SizedBox(height: 10),
                  for (final u in auth.encargados)
                    Card(
                      child: ListTile(
                        title: Text(u.nombre, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${nombreEquipo(u.equipoId)} · ${u.pin.isEmpty ? 'Todavía no crea su PIN' : 'Tiene PIN'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        trailing: u.pin.isEmpty
                            ? null
                            : OutlinedButton(
                                onPressed: () {
                                  auth.borrarPin(u);
                                  _aviso('PIN de ${u.nombre} borrado');
                                },
                                child: const Text('Borrar PIN'),
                              ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('Mi contraseña', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
                  const SizedBox(height: 10),
                  _campo('Contraseña actual', _actual),
                  _campo('Contraseña nueva', _nueva),
                  _campo('Repite la contraseña nueva', _repetir),
                  TextoError(_error),
                  const SizedBox(height: 12),
                  BotonGrande(texto: 'Cambiar contraseña', estilo: EstiloBoton.primario, onTap: _cambiarPassword),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
