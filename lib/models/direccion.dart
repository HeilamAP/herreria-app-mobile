/// Dirección capturada por partes, como se usan en Mérida:
/// calle, número, cruzamientos ("entre 53 y 55"), colonia y municipio.
/// La línea armada ([linea]) es lo que se muestra y lo que se busca en el mapa.
class PartesDireccion {
  String calle;
  String numero;
  String cruce1;
  String cruce2;
  String colonia;
  String municipio;
  String referencias; // "Portón negro, frente a la tienda" (no se manda al mapa)

  PartesDireccion({
    this.calle = '',
    this.numero = '',
    this.cruce1 = '',
    this.cruce2 = '',
    this.colonia = '',
    this.municipio = municipioPredeterminado,
    this.referencias = '',
  });

  static const municipioPredeterminado = 'Mérida';

  /// "Calle 60 #450 x 53 y 55, Col. Centro, Mérida". Si la calle tiene nombre
  /// ("Av. Itzaes") no se le antepone "Calle".
  String get linea {
    final c = calle.trim(), n = numero.trim(), c1 = cruce1.trim(), c2 = cruce2.trim();
    var primera = c.isEmpty ? '' : (RegExp(r'^\d').hasMatch(c) ? 'Calle $c' : c);
    if (n.isNotEmpty) primera += '${primera.isEmpty ? '' : ' '}#$n';
    final cruces = [c1, c2].where((x) => x.isNotEmpty).join(' y ');
    if (cruces.isNotEmpty) primera += '${primera.isEmpty ? '' : ' '}x $cruces';
    final col = colonia.trim();
    return [
      primera,
      if (col.isNotEmpty) RegExp(r'^col', caseSensitive: false).hasMatch(col) ? col : 'Col. $col',
      municipio.trim(),
    ].where((x) => x.isNotEmpty).join(', ');
  }

  factory PartesDireccion.fromJson(Map<String, dynamic> json) => PartesDireccion(
        calle: json['calle'] ?? '',
        numero: json['numero'] ?? '',
        cruce1: json['cruce1'] ?? '',
        cruce2: json['cruce2'] ?? '',
        colonia: json['colonia'] ?? '',
        municipio: json['municipio'] ?? municipioPredeterminado,
        referencias: json['referencias'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'calle': calle,
        'numero': numero,
        'cruce1': cruce1,
        'cruce2': cruce2,
        'colonia': colonia,
        'municipio': municipio,
        'referencias': referencias,
      };
}
