import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Widget guard que muestra [child] solo si el usuario tiene acceso,
/// y [fallback] (por defecto nada) en caso contrario.
///
/// Uso por permiso:
/// ```dart
/// RolGuard(
///   permiso: 'productos.eliminar',
///   child: IconButton(icon: Icon(Icons.delete), onPressed: onEliminar),
/// )
/// ```
///
/// Uso por rol:
/// ```dart
/// RolGuard(
///   roles: ['superadmin', 'admin_inventario'],
///   child: BtnCrearProducto(),
/// )
/// ```
class RolGuard extends StatelessWidget {
  final String? permiso;
  final List<String>? roles;
  final Widget child;
  final Widget? fallback;

  const RolGuard({
    super.key,
    this.permiso,
    this.roles,
    required this.child,
    this.fallback,
  }) : assert(
          permiso != null || roles != null,
          'RolGuard requiere al menos permiso o roles',
        );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    bool tieneAcceso = false;

    if (auth.esSuperAdmin) {
      tieneAcceso = true;
    } else if (permiso != null) {
      tieneAcceso = auth.tienePermiso(permiso!);
    } else if (roles != null) {
      tieneAcceso = auth.esAlgunRol(roles!);
    }

    if (tieneAcceso) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
