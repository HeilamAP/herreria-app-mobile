import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'encargado/ui.dart';

/// Entrada: los encargados tocan su nombre y escriben su PIN.
/// El administrador entra con usuario y contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Modo { quien, pin, admin }

class _LoginScreenState extends State<LoginScreen> {
  _Modo _modo = _Modo.quien;
  Usuario? _usuario;
  String _pin = '';
  String? _pinNuevo; // al crear PIN: el primero que escribió
  String? _error;
  Timer? _reloj;

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _reloj?.cancel();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _creando => _usuario != null && _usuario!.pin.isEmpty;

  void _irA(_Modo modo, {Usuario? usuario}) => setState(() {
        _modo = modo;
        _usuario = usuario;
        _pin = '';
        _pinNuevo = null;
        _error = null;
      });

  void _tecla(String k) {
    final auth = context.read<AuthService>();
    if (_usuario != null && auth.segundosBloqueado(_usuario!.id) > 0) return;
    setState(() {
      _error = null;
      if (k == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (_pin.length < 4) _pin += k;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), _pinCompleto);
    }
  }

  void _pinCompleto() {
    if (!mounted || _pin.length != 4) return;
    final auth = context.read<AuthService>();
    if (_creando) {
      if (_pinNuevo == null) {
        setState(() {
          _pinNuevo = _pin;
          _pin = '';
        });
      } else if (_pinNuevo == _pin) {
        auth.crearPinYEntrar(_usuario!, _pin);
      } else {
        setState(() {
          _pinNuevo = null;
          _pin = '';
          _error = 'Los dos PIN no son iguales. Empieza otra vez.';
        });
      }
      return;
    }
    final error = auth.loginConPin(_usuario!, _pin);
    if (error != null) {
      setState(() {
        _pin = '';
        _error = error;
      });
      if (auth.segundosBloqueado(_usuario!.id) > 0) _iniciarCuentaAtras();
    }
  }

  void _iniciarCuentaAtras() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _usuario == null) return t.cancel();
      final s = context.read<AuthService>().segundosBloqueado(_usuario!.id);
      setState(() => _error = s > 0 ? 'Espera $s segundos e inténtalo otra vez.' : null);
      if (s == 0) t.cancel();
    });
  }

  void _entrarAdmin() {
    context.read<AuthService>().login(
          _userCtrl.text,
          _passCtrl.text,
          onError: (msg) => setState(() => _error = msg),
        );
  }

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: PopScope(
        canPop: _modo == _Modo.quien,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _irA(_Modo.quien);
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: switch (_modo) {
                    _Modo.quien => _quien(),
                    _Modo.pin => _pantallaPin(),
                    _Modo.admin => _admin(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _quien() {
    final encargados = context.watch<AuthService>().encargados;
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          ClipOval(
            child: Image.asset('assets/logo/logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.door_sliding_outlined, size: 48, color: EC.acento)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AY OY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EC.texto, letterSpacing: 1)),
                Text('Herrería Artística en General', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text('¿Quién eres?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: EC.texto)),
      Text('Toca tu nombre', style: TextStyle(fontSize: 19, color: EC.textoSuave)),
      const SizedBox(height: 18),
      for (final u in encargados) ...[
        _tarjetaPersona(u),
        const SizedBox(height: 14),
      ],
      const SizedBox(height: 24),
      Center(
        child: TextButton.icon(
          onPressed: () => _irA(_Modo.admin),
          icon: Icon(Icons.admin_panel_settings_outlined, color: EC.textoSuave),
          label: Text('Soy el administrador', style: TextStyle(fontSize: 17, color: EC.textoSuave)),
        ),
      ),
    ];
  }

  Widget _tarjetaPersona(Usuario u) {
    return Material(
      color: EC.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: EC.borde)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _irA(_Modo.pin, usuario: u);
          if (context.read<AuthService>().segundosBloqueado(u.id) > 0) _iniciarCuentaAtras();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: EC.acentoFondo,
                child: Text(u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: EC.acentoTexto)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nombre, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: EC.texto)),
                    Text(nombreEquipo(u.equipoId), style: TextStyle(fontSize: 18, color: EC.textoSuave)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 34, color: EC.textoSuave),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pantallaPin() {
    final u = _usuario!;
    final titulo = !_creando
        ? 'Hola, ${u.nombre.split(' ').first}'
        : _pinNuevo == null
            ? 'Crea tu PIN'
            : 'Escríbelo otra vez';
    final ayuda = !_creando
        ? 'Escribe tus 4 números'
        : _pinNuevo == null
            ? 'Inventa 4 números que puedas recordar. Los usarás cada vez que entres.'
            : 'Para estar seguros de que lo recuerdas';
    return [
      Encabezado(titulo: titulo, onAtras: () => _irA(_Modo.quien)),
      Text(ayuda, style: TextStyle(fontSize: 19, color: EC.textoSuave)),
      const SizedBox(height: 26),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? EC.texto : Colors.transparent,
                border: Border.all(color: EC.bordeFuerte, width: 2.5),
              ),
            ),
        ],
      ),
      Center(child: TextoError(_error)),
      const SizedBox(height: 22),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'])
            if (k.isEmpty)
              const SizedBox.shrink()
            else
              BotonGrande(
                texto: k == '<' ? '' : k,
                icono: k == '<' ? Icons.backspace_outlined : null,
                fontSize: 30,
                onTap: () => _tecla(k),
              ),
        ],
      ),
      if (!_creando) ...[
        const SizedBox(height: 18),
        Text('¿Olvidaste tu PIN? Pídele al administrador que lo borre y crea uno nuevo.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: EC.textoSuave)),
      ],
    ];
  }

  List<Widget> _admin() {
    return [
      Encabezado(titulo: 'Administrador', onAtras: () => _irA(_Modo.quien)),
      const SizedBox(height: 16),
      CampoGrande(etiqueta: 'Usuario', controller: _userCtrl, mayusculas: TextCapitalization.none, onChanged: (_) => setState(() => _error = null)),
      const SizedBox(height: 18),
      Text('Contraseña', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: EC.texto)),
      const SizedBox(height: 8),
      TextField(
        controller: _passCtrl,
        obscureText: true,
        style: const TextStyle(fontSize: 21),
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _entrarAdmin(),
      ),
      TextoError(_error),
      const SizedBox(height: 24),
      BotonGrande(texto: 'Entrar', icono: Icons.login, estilo: EstiloBoton.primario, onTap: _entrarAdmin),
    ];
  }
}
