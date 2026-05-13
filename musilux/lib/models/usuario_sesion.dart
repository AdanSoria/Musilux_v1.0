import 'rol_model.dart';

class UsuarioSesion {
  final String id;
  final String nombres;
  final String apellidos;
  final String correo;
  final RolModel rol;

  const UsuarioSesion({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.rol,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) => UsuarioSesion(
        id: json['id']?.toString() ?? '',
        nombres: json['nombres']?.toString() ?? '',
        apellidos: json['apellidos']?.toString() ?? '',
        correo: json['correo']?.toString() ?? '',
        rol: RolModel.fromJson(json),
      );

  bool tienePermiso(String permiso) => rol.tienePermiso(permiso);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
        ...rol.toJson(),
      };
}
