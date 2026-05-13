class RolModel {
  final int id;
  final String nombre;
  final List<String> permisos;

  const RolModel({
    required this.id,
    required this.nombre,
    required this.permisos,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) => RolModel(
        id: json['id_rol'] as int? ?? 0,
        nombre: json['rol']?.toString() ?? 'visitante',
        permisos: List<String>.from(json['permisos'] ?? []),
      );

  bool get esSuperAdmin    => nombre == 'superadmin';
  bool get esCliente       => nombre == 'cliente';
  bool get esVisitante     => nombre == 'visitante';
  bool get esAdminPedidos  => nombre == 'admin_pedidos';
  bool get esAdminUsuarios => nombre == 'admin_usuarios';
  bool get esAdminInventario => nombre == 'admin_inventario';
  bool get esAdminVentas   => nombre == 'admin_ventas';
  bool get esAdminSoporte  => nombre == 'admin_soporte';

  bool tienePermiso(String permiso) =>
      esSuperAdmin || permisos.contains(permiso);

  Map<String, dynamic> toJson() => {
        'id_rol': id,
        'rol': nombre,
        'permisos': permisos,
      };
}
