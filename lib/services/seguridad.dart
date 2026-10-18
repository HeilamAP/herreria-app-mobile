import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Cifrado de contraseñas y PIN: SHA-256 con sal aleatoria y varias vueltas.
/// Formato guardado: `sha256$<sal>$<hash>`.
class Seguridad {
  static const _prefijo = 'sha256';
  static const _vueltas = 5000;

  static bool esHash(String valor) => valor.startsWith('$_prefijo\$');

  static String cifrar(String secreto) {
    final rnd = Random.secure();
    final sal = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return '$_prefijo\$$sal\$${_digerir(sal, secreto)}';
  }

  static bool verificar(String secreto, String guardado) {
    if (guardado.isEmpty) return false;
    final partes = guardado.split('\$');
    if (partes.length != 3 || partes[0] != _prefijo) return false;
    return _igualSeguro(_digerir(partes[1], secreto), partes[2]);
  }

  static String _digerir(String sal, String secreto) {
    List<int> bytes = utf8.encode('$sal:$secreto');
    for (var i = 0; i < _vueltas; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _igualSeguro(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }
}
