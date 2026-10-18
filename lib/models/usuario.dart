class Usuario {
  final String id;
  String nombre;
  String username;
  String password; // cifrada (ver Seguridad)
  String pin; // cifrado; vacío = el encargado aún no crea su PIN
  String rol; // "Administrador" or "Empleado"
  String equipoId; // "equipo1", "equipo2", "todos"

  bool get isAdmin => rol.toLowerCase() == 'administrador';

  Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    required this.password,
    required this.rol,
    this.pin = '',
    this.equipoId = 'equipo1',
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? json['Id'] ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
      username: json['username'] ?? json['Username'] ?? '',
      password: json['password'] ?? json['Password'] ?? '',
      pin: json['pin'] ?? json['Pin'] ?? '',
      rol: json['rol'] ?? json['Rol'] ?? 'Empleado',
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'username': username,
    'password': password,
    'pin': pin,
    'rol': rol,
    'equipoId': equipoId,
  };
}
