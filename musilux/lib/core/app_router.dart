import '../providers/auth_provider.dart';

/// Constantes de rutas nombradas de la app.
class AppRoutes {
  // Públicas
  static const catalogoPublico = '/';
  static const login           = '/login';

  // Chat IA
  static const chat = '/chat';

  // Cliente
  static const tiendaHome = '/tienda';
  static const carrito    = '/carrito';
  static const checkout   = '/checkout';
  static const misCompras = '/mis-compras';
  static const descargas  = '/descargas';
  static const wishlist   = '/wishlist';
  static const perfil     = '/perfil';
  static const soporte    = '/soporte';

  // Admin — panel legacy (mantiene compatibilidad)
  static const adminProducts = '/admin-products';

  // Admin — dashboards por rol
  static const superAdminDashboard  = '/admin/dashboard';
  static const pedidosDashboard     = '/admin/pedidos';
  static const usuariosDashboard    = '/admin/usuarios';
  static const inventarioDashboard  = '/admin/inventario';
  static const ventasDashboard      = '/admin/ventas';
  static const soporteDashboard     = '/admin/soporte';
}

/// Lógica de navegación basada en roles.
/// Flutter valida en cliente como capa de UX;
/// la validación real ocurre siempre en el backend.
class AppRouter {
  /// Ruta home a la que redirigir tras un login exitoso.
  static String homeSegunRol(String rol) {
    switch (rol) {
      case 'superadmin':
        return AppRoutes.superAdminDashboard;
      case 'admin_inventario':
        return AppRoutes.inventarioDashboard;
      case 'admin_pedidos':
        return AppRoutes.pedidosDashboard;
      case 'admin_usuarios':
        return AppRoutes.usuariosDashboard;
      case 'admin_ventas':
        return AppRoutes.ventasDashboard;
      case 'admin_soporte':
        return AppRoutes.soporteDashboard;
      case 'cliente':
        return AppRoutes.catalogoPublico;
      default:
        return AppRoutes.catalogoPublico;
    }
  }

  /// Verifica si el usuario actual puede navegar a [ruta].
  static bool puedeNavegar(String ruta, AuthProvider auth) {
    if (auth.esSuperAdmin) return true;
    final permitidas = _rutasPermitidas[auth.rolActual] ?? {};
    return permitidas.contains(ruta);
  }

  static const Map<String, Set<String>> _rutasPermitidas = {
    'visitante': {
      AppRoutes.catalogoPublico,
      AppRoutes.login,
    },
    'cliente': {
      AppRoutes.catalogoPublico,
      AppRoutes.tiendaHome,
      AppRoutes.carrito,
      AppRoutes.checkout,
      AppRoutes.misCompras,
      AppRoutes.descargas,
      AppRoutes.wishlist,
      AppRoutes.perfil,
      AppRoutes.soporte,
      AppRoutes.chat,
    },
    'admin_pedidos': {
      AppRoutes.pedidosDashboard,
    },
    'admin_usuarios': {
      AppRoutes.usuariosDashboard,
    },
    'admin_inventario': {
      AppRoutes.inventarioDashboard,
      AppRoutes.adminProducts, // compatibilidad con pantalla existente
    },
    'admin_ventas': {
      AppRoutes.ventasDashboard,
    },
    'admin_soporte': {
      AppRoutes.soporteDashboard,
    },
  };
}
