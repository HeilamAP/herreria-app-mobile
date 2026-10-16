class Empleado {
  final String id;
  String nombre;
  String puesto;
  String equipoId; // "equipo1" | "equipo2"

  Empleado({
    required this.id,
    required this.nombre,
    required this.puesto,
    this.equipoId = 'equipo1',
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] ?? json['Id'] ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
      puesto: json['puesto'] ?? json['Puesto'] ?? '',
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'puesto': puesto,
        'equipoId': equipoId,
      };
}
