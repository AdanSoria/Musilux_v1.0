import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/cart_provider.dart';
import '../models/chat_message.dart';
import '../models/cart_item.dart';
import '../core/app_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/payment_service.dart';
import '../utils/browser_utils.dart';
import '../services/api_service.dart';
import '../models/product.dart';

// ==========================================
// LAYOUT BASE (Header, Footer, Drawers)
// ==========================================
class BaseLayout extends StatelessWidget {
  final Widget child;
  const BaseLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const NavDrawer(),
      endDrawer: const CartDrawer(),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [child, const CustomFooter()]),
            ),
          ),
        ],
      ),
      // Burbuja flotante del chatbot — solo visible para usuarios autenticados
      floatingActionButton: auth.estaAutenticado ? const _ChatFab() : null,
    );
  }
}

// ==========================================
// ENCABEZADO (Header y Barra de Navegación)
// ==========================================
class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      height: 70,
      color: AppColors.headerBg,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (ModalRoute.of(context)?.settings.name != '/') {
                  Navigator.pushNamed(context, '/');
                }
              },
              child: const Text(
                'Musilux',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _NavBarItem(
              title: 'Instrumentos',
              route: '/instrumentos',
              onTap: () => Navigator.pushNamed(context, '/instrumentos'),
            ),
            _NavBarItem(
              title: 'Iluminación',
              route: '/iluminacion',
              onTap: () => Navigator.pushNamed(context, '/iluminacion'),
            ),
            _NavBarItem(
              title: 'Vinilos',
              route: '/vinilos',
              onTap: () => Navigator.pushNamed(context, '/vinilos'),
            ),
            _NavBarItem(
              title: 'Contacto',
              route: '/contacto',
              onTap: () => Navigator.pushNamed(context, '/contacto'),
            ),
            const SizedBox(width: 20),
          ],

          // --- BOTÓN DE BUSCADOR FUNCIONAL ---
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              showSearch(context: context, delegate: ProductSearchDelegate());
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white70,
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),

          // --- BOTÓN ADMIN INTELIGENTE (visible solo para roles admin) ---
          const _AdminMenuButton(),

          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTÓN ADMIN INTELIGENTE
// Visible solo para roles administrativos. Superadmin ve un menú con todas las
// secciones; cada admin específico va directo a su dashboard.
// ─────────────────────────────────────────────────────────────────────────────
class _AdminMenuButton extends StatelessWidget {
  const _AdminMenuButton();

  // Etiqueta legible por rol
  static String _labelRol(String rol) {
    switch (rol) {
      case 'admin_pedidos':
        return 'Gestión de Pedidos';
      case 'admin_usuarios':
        return 'Gestión de Usuarios';
      case 'admin_inventario':
        return 'Inventario';
      case 'admin_ventas':
        return 'Ventas';
      case 'admin_soporte':
        return 'Soporte';
      default:
        return 'Panel Admin';
    }
  }

  // Icono por sección
  static IconData _iconRol(String rol) {
    switch (rol) {
      case 'admin_pedidos':
        return Icons.receipt_long_outlined;
      case 'admin_usuarios':
        return Icons.people_outline;
      case 'admin_inventario':
        return Icons.inventory_2_outlined;
      case 'admin_ventas':
        return Icons.bar_chart_outlined;
      case 'admin_soporte':
        return Icons.support_agent_outlined;
      default:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Sin sesión o rol no-admin → oculto
    if (!auth.estaAutenticado) return const SizedBox.shrink();
    if (auth.esCliente || auth.rolActual == 'visitante') {
      return const SizedBox.shrink();
    }

    // ── Superadmin: menú desplegable con TODAS las secciones ──────────────
    if (auth.esSuperAdmin) {
      return PopupMenuButton<String>(
        tooltip: 'Panel de Administración',
        onSelected: (ruta) => Navigator.pushNamed(context, ruta),
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              color: AppColors.primaryPurple,
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        itemBuilder: (_) => [
          // Cabecera informativa (no navegable)
          PopupMenuItem(
            enabled: false,
            height: 36,
            child: Text(
              'SUPER ADMIN — Acceso total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPurple,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const PopupMenuDivider(),
          _menuItem(
            AppRoutes.superAdminDashboard,
            Icons.dashboard_outlined,
            'Dashboard principal',
          ),
          _menuItem(
            AppRoutes.pedidosDashboard,
            Icons.receipt_long_outlined,
            'Gestión de Pedidos',
          ),
          _menuItem(
            AppRoutes.usuariosDashboard,
            Icons.people_outline,
            'Gestión de Usuarios',
          ),
          _menuItem(
            AppRoutes.inventarioDashboard,
            Icons.inventory_2_outlined,
            'Inventario / Productos',
          ),
          _menuItem(
            AppRoutes.ventasDashboard,
            Icons.bar_chart_outlined,
            'Ventas',
          ),
          _menuItem(
            AppRoutes.soporteDashboard,
            Icons.support_agent_outlined,
            'Soporte',
          ),
        ],
      );
    }

    // ── Admin específico: botón directo a su dashboard ────────────────────
    final ruta = AppRouter.homeSegunRol(auth.rolActual);
    final label = _labelRol(auth.rolActual);
    final icono = _iconRol(auth.rolActual);

    return IconButton(
      icon: Icon(icono, color: Colors.white70),
      tooltip: label,
      onPressed: () => Navigator.pushNamed(context, ruta),
    );
  }

  /// Construye un ítem de menú con icono y texto.
  static PopupMenuItem<String> _menuItem(
    String ruta,
    IconData icono,
    String label,
  ) {
    return PopupMenuItem<String>(
      value: ruta,
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final String? route;

  const _NavBarItem({required this.title, required this.onTap, this.route});

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isActive = widget.route != null && currentRoute == widget.route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive || _hovered
                      ? AppColors.primaryPurple
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              widget.title,
              style: TextStyle(
                color: isActive
                    ? AppColors.primaryPurple
                    : (_hovered ? Colors.white : Colors.white70),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PIE DE PÁGINA (Footer)
// ==========================================
class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: const Column(
        children: [
          Text(
            'Contacto: info@musilux.com | Tel: 311 123 8040',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          SizedBox(height: 8),
          Text(
            'Enlaces Útiles: Términos y Condiciones | Política de Privacidad',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MENÚ DE NAVEGACIÓN MÓVIL (Drawer Izquierdo)
// ==========================================
class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.headerBg),
            child: Center(
              child: Text(
                'Musilux',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Instrumentos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/instrumentos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Iluminación'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/iluminacion');
            },
          ),
          ListTile(
            leading: const Icon(Icons.album),
            title: const Text('Vinilos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vinilos');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Contacto'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contacto');
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CARRITO DE COMPRAS (Drawer Derecho)
// ==========================================
class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final drawerWidth = isMobile ? screenWidth * 0.88 : screenWidth * 0.35;
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: AppColors.background,
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            return Column(
              children: [
                // ── Cabecera ──────────────────────────────────────────────────
                _CartHeader(totalUnidades: cart.totalUnidades),

                // ── Alerta de precios modificados ─────────────────────────────
                if (cart.itemsConPrecioCambiado.isNotEmpty)
                  _PrecioAlertaBanner(items: cart.itemsConPrecioCambiado),

                // ── Lista de items ────────────────────────────────────────────
                Expanded(
                  child: cart.isEmpty
                      ? const _CarritoVacio()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: cart.items.length,
                          itemBuilder: (_, i) => _CartItemTile(
                            item: cart.items[i],
                            onIncrementar: () => _cambiarCantidad(
                              context,
                              cart,
                              cart.items[i],
                              cart.items[i].cantidad + 1,
                            ),
                            onDecrementar: () => _cambiarCantidad(
                              context,
                              cart,
                              cart.items[i],
                              cart.items[i].cantidad - 1,
                            ),
                            onEliminar: () =>
                                cart.eliminarProducto(cart.items[i].productoId),
                          ),
                        ),
                ),

                // ── Resumen financiero + botón checkout ───────────────────────
                if (!cart.isEmpty) _CartResumen(cart: cart),
              ],
            );
          },
        ),
      ),
    );
  }

  void _cambiarCantidad(
    BuildContext context,
    CartProvider cart,
    CartItem item,
    int nueva,
  ) {
    final resultado = cart.actualizarCantidad(item.productoId, nueva);
    if (resultado == CartUpdateResult.limiteStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock máximo disponible: ${item.stockDisponible}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (resultado == CartUpdateResult.limiteNegocio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 10 unidades por producto.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Cabecera del carrito ──────────────────────────────────────────────────────
class _CartHeader extends StatelessWidget {
  final int totalUnidades;
  const _CartHeader({required this.totalUnidades});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 16;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad, 12, 16),
      decoration: const BoxDecoration(color: AppColors.headerBg),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mi Carrito${totalUnidades > 0 ? ' ($totalUnidades)' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

// ── Banner de alerta: precio cambió ──────────────────────────────────────────
class _PrecioAlertaBanner extends StatelessWidget {
  final List<CartItem> items;
  const _PrecioAlertaBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'El precio de ${items.length == 1 ? items.first.nombre : '${items.length} productos'} '
              'cambió desde que los agregaste.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────
class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora el catálogo y agrega\nproductos que te gusten',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/');
            },
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Ver catálogo'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de un item ───────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEliminar;

  const _CartItemTile({
    required this.item,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Imagen miniatura
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imagenUrl.isNotEmpty
                  ? Image.network(
                      item.imagenUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context2, e, _) =>
                          _ImagenPlaceholder(nombre: item.nombre),
                    )
                  : _ImagenPlaceholder(nombre: item.nombre),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${item.precioUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.precioModificado) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.trending_up,
                          size: 13,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Subtotal: \$${item.subtotalLinea.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Controles de cantidad
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar',
                ),
                const SizedBox(height: 4),
                _CantidadControl(
                  cantidad: item.cantidad,
                  onIncrementar: item.cantidad < item.stockDisponible
                      ? onIncrementar
                      : null,
                  onDecrementar: onDecrementar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control +/– de cantidad ───────────────────────────────────────────────────
class _CantidadControl extends StatelessWidget {
  final int cantidad;
  final VoidCallback? onIncrementar;
  final VoidCallback onDecrementar;

  const _CantidadControl({
    required this.cantidad,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: Icons.remove,
            onTap: onDecrementar,
            color: AppColors.textSecondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$cantidad',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          _Btn(
            icon: Icons.add,
            onTap: onIncrementar,
            color: onIncrementar != null
                ? AppColors.primaryPurple
                : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _Btn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _ImagenPlaceholder extends StatelessWidget {
  final String nombre;
  const _ImagenPlaceholder({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}

// ── Resumen financiero + Checkout ─────────────────────────────────────────────
class _CartResumen extends StatelessWidget {
  final CartProvider cart;
  const _CartResumen({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón vaciar
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text(
                      '¿Eliminar todos los productos del carrito?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Vaciar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<CartProvider>().vaciarCarrito();
                }
              },
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 16,
                color: AppColors.error,
              ),
              label: const Text(
                'Vaciar',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Líneas de cálculo
          _LineaCalculo(
            label: 'Subtotal (${cart.totalUnidades} art.)',
            valor: cart.subtotal,
          ),
          const SizedBox(height: 4),
          _LineaCalculo(label: 'IVA (16 %) — incluido', valor: cart.impuestos),
          const Divider(height: 20),
          _LineaCalculo(
            label: 'Total',
            valor: cart.total,
            bold: true,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(height: 16),

          // Botón checkout
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final scaffold = ScaffoldMessenger.of(context);
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Iniciando pago...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                final paymentService = PaymentService();

                // Web flow: use Stripe Checkout (hosted) since PaymentSheet is not supported
                if (kIsWeb) {
                  // Pedir dirección de envío con formulario estructurado
                  final nombreCtrl = TextEditingController();
                  final apellidoCtrl = TextEditingController();
                  final calleCtrl = TextEditingController();
                  final aptoCtrl = TextEditingController();
                  final ciudadCtrl = TextEditingController();
                  final estadoCtrl = TextEditingController();
                  final postalCtrl = TextEditingController();
                  final telefonoCtrl = TextEditingController();
                  String paisValue = 'Mexico';

                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx2, setState2) {
                        return AlertDialog(
                          title: const Text('Dirección de envío'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: nombreCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: apellidoCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Apellido',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: calleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Calle y número',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: aptoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Apto / Colonia (opcional)',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: ciudadCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Ciudad',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: estadoCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Estado / Provincia',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: postalCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Código postal',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: paisValue,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Mexico',
                                            child: Text('Mexico'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Peru',
                                            child: Text('Peru'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'USA',
                                            child: Text('USA'),
                                          ),
                                        ],
                                        onChanged: (v) => setState2(
                                          () => paisValue = v ?? paisValue,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'País',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: telefonoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono (opcional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx2, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Validación mínima: campos obligatorios
                                if (nombreCtrl.text.trim().isEmpty ||
                                    calleCtrl.text.trim().isEmpty ||
                                    ciudadCtrl.text.trim().isEmpty ||
                                    postalCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Completa Nombre, Calle, Ciudad y Código postal',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx2, true);
                              },
                              child: const Text('Continuar'),
                            ),
                          ],
                        );
                      },
                    ),
                  );

                  if (ok != true) {
                    scaffold.hideCurrentSnackBar();
                    scaffold.showSnackBar(
                      const SnackBar(
                        content: Text('Pago cancelado: dirección requerida'),
                      ),
                    );
                    return;
                  }

                  // Construir dirección combinada para persistir en DB
                  final parts = <String>[];
                  final nombre = nombreCtrl.text.trim();
                  final apellido = apellidoCtrl.text.trim();
                  final calle = calleCtrl.text.trim();
                  if (calle.isNotEmpty) parts.add(calle);
                  final apto = aptoCtrl.text.trim();
                  if (apto.isNotEmpty) parts.add(apto);
                  final ciudad = ciudadCtrl.text.trim();
                  final estado = estadoCtrl.text.trim();
                  final postal = postalCtrl.text.trim();
                  final pais = paisValue;
                  final telefono = telefonoCtrl.text.trim();
                  final locale = [
                    if (ciudad.isNotEmpty) ciudad,
                    if (estado.isNotEmpty) estado,
                    if (postal.isNotEmpty) postal,
                    if (pais.isNotEmpty) pais,
                  ].join(', ');
                  if (locale.isNotEmpty) parts.add(locale);
                  if (telefono.isNotEmpty) parts.add('Tel: $telefono');

                  final direccionEnvio = parts.join(' • ');

                  final payload = cart.buildOrdenPayload(direccionEnvio);
                  payload['amount'] = cart.total;
                  payload['direccion_envio'] = direccionEnvio;
                  // Añadir campos individuales para que el backend construya la guia_envio
                  payload['nombre'] = nombre;
                  payload['apellido'] = apellido;
                  payload['telefono'] = telefono;

                  final resp = await paymentService.createCheckoutSessionUrl(
                    payload,
                  );
                  if (resp['success'] == true && resp['url'] != null) {
                    final url = resp['url'] as String;
                    // Open in new tab/window (no-op on non-web)
                    openUrlInBrowser(url);
                    scaffold.showSnackBar(
                      const SnackBar(
                        content: Text('Redirigiendo a Stripe Checkout...'),
                      ),
                    );
                    // keep drawer open — user will return to the site after checkout
                    return;
                  } else {
                    final message =
                        resp['message']?.toString() ??
                        'Error creando sesión de pago.';
                    scaffold.showSnackBar(SnackBar(content: Text(message)));
                    return;
                  }
                }

                // Mobile/native flow: PaymentSheet
                try {
                  final result = await paymentService.payWithPaymentSheet(
                    cart.total,
                  );
                  final ok = result['success'] == true;
                  final message =
                      result['message']?.toString() ??
                      (ok
                          ? 'Pago realizado correctamente'
                          : 'Error al procesar el pago');
                  scaffold.showSnackBar(SnackBar(content: Text(message)));
                  if (ok) Navigator.pop(context);
                } catch (e) {
                  scaffold.showSnackBar(
                    SnackBar(content: Text('Error al iniciar pago: $e')),
                  );
                }
              },
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(
                'Pagar  \$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaCalculo extends StatelessWidget {
  final String label;
  final double valor;
  final bool bold;
  final Color? color;

  const _LineaCalculo({
    required this.label,
    required this.valor,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      color: color ?? AppColors.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('\$${valor.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

// ==========================================
// TARJETA DE CATEGORÍA
// ==========================================
class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;
  final double? width;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 300,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              memCacheWidth: 900,
              memCacheHeight: 540,
              errorWidget: (c, u, e) => Container(color: Colors.grey),
            ),
            Container(color: Colors.black.withValues(alpha: 0.4)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TARJETA DE PRODUCTO
// ==========================================
class ProductCard extends StatelessWidget {
  final String title;
  final double price;
  final String imageUrl;
  final List<String> tags;
  final VoidCallback onDetailsTap;
  final VoidCallback? onAdd;
  final bool isSale;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.tags,
    required this.onDetailsTap,
    this.onAdd,
    this.isSale = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetailsTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Imagen con badge de oferta ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    memCacheWidth: 750,
                    memCacheHeight: 600,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textDisabled,
                        size: 36,
                      ),
                    ),
                  ),
                  if (isSale)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.priceSale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OFERTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Información del producto ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .take(2)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tagBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppColors.tagText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (tags.isNotEmpty) const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      FilledButton(
                        onPressed:
                            onAdd ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Agregado al carrito'),
                                ),
                              );
                            },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.add_shopping_cart, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DELEGADO DEL BUSCADOR (SearchDelegate)
// ==========================================
class ProductSearchDelegate extends SearchDelegate<String> {
  // Load product names dynamically from the backend to avoid hardcoded lists.
  final ApiService _apiService = ApiService();
  // Cache by query to avoid repeated network calls
  final Map<String, List<String>> _cache = {};
  Future<List<String>>? _productsFuture;
  // Simple debounce token
  DateTime? _lastQueryTime;

  @override
  String get searchFieldLabel => 'Buscar en Musilux...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // If query cached, return immediately
    if (query.isNotEmpty && _cache.containsKey(query.toLowerCase())) {
      final results = _cache[query.toLowerCase()]!;
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(
              Icons.music_note,
              color: AppColors.primaryPurple,
            ),
            title: Text(results[index]),
            onTap: () {
              close(context, results[index]);
              Navigator.pushNamed(context, '/producto_detalle');
            },
          );
        },
      );
    }

    // Debounce: only query if last change was > 300ms ago
    _lastQueryTime = DateTime.now();
    final currentQueryTime = _lastQueryTime;

    _productsFuture = Future.delayed(const Duration(milliseconds: 300)).then((
      _,
    ) async {
      // if another query happened in the meantime, abort this fetch
      if (currentQueryTime != _lastQueryTime) return <String>[];

      try {
        final List<Product> products = await _apiService.fetchProducts(
          search: query,
          perPage: 20,
        );
        final names = products.map((p) => p.nombre).toList();
        if (query.isNotEmpty) {
          _cache[query.toLowerCase()] = names;
        }
        return names;
      } catch (e) {
        // on error, return empty list — UI will show no results
        return <String>[];
      }
    });

    return FutureBuilder<List<String>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error cargando resultados: ${snapshot.error}'),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron resultados para "$query"',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(
                Icons.music_note,
                color: AppColors.primaryPurple,
              ),
              title: Text(results[index]),
              onTap: () {
                close(context, results[index]);
                Navigator.pushNamed(context, '/producto_detalle');
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _productsFuture ??= _apiService.fetchProducts().then(
      (list) => list.map((p) => p.nombre).toList(),
    );

    return FutureBuilder<List<String>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While loading, show a small loader or default suggestions
          if (query.isEmpty) {
            return ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.search, color: Colors.grey),
                  title: Text('Cargando sugerencias...'),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data ?? [];

        final suggestions = query.isEmpty
            ? (products.isNotEmpty
                  ? products.take(6).toList()
                  : ['Guitarra', 'Luces LED', 'Vinilos Rock'])
            : products
                  .where((p) => p.toLowerCase().contains(query.toLowerCase()))
                  .toList();

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.search, color: Colors.grey),
              title: Text(suggestions[index]),
              onTap: () {
                query = suggestions[index];
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT FAB — Burbuja flotante que abre el chat del asistente IA
// ─────────────────────────────────────────────────────────────────────────────
class _ChatFab extends StatefulWidget {
  const _ChatFab();

  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _abrirChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: FloatingActionButton(
        onPressed: () => _abrirChat(context),
        backgroundColor: AppColors.primaryPurple,
        elevation: 6,
        tooltip: 'Asistente Musilux',
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
            // Punto verde "en línea"
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPurple,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MODAL — Ventana emergente con la interfaz del chatbot
// ─────────────────────────────────────────────────────────────────────────────
class _ChatModal extends StatefulWidget {
  const _ChatModal();

  @override
  State<_ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<_ChatModal> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty) return;
    _inputCtrl.clear();
    await context.read<ChatProvider>().enviarMensaje(texto);
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle + Cabecera ────────────────────────────────────────
              _ChatModalHeader(
                onNuevoChat: () async =>
                    context.read<ChatProvider>().nuevaConversacion(),
                onCerrar: () => Navigator.pop(context),
              ),

              // ── Lista de mensajes ────────────────────────────────────────
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chat, _) {
                    // Mostrar error como snackbar
                    if (chat.error != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(chat.error!),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        chat.clearError();
                      });
                    }

                    if (chat.cargando) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (chat.mensajes.isEmpty) {
                      return _ChatBienvenida(
                        onSugerencia: (texto) async {
                          await chat.enviarMensaje(texto);
                          _scrollAlFinal();
                        },
                      );
                    }

                    _scrollAlFinal();
                    final total =
                        chat.mensajes.length + (chat.enviando ? 1 : 0);

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      itemCount: total,
                      itemBuilder: (_, i) {
                        if (chat.enviando && i == chat.mensajes.length) {
                          return const _TypingIndicatorInline();
                        }
                        return _BurbujaMensaje(mensaje: chat.mensajes[i]);
                      },
                    );
                  },
                ),
              ),

              // ── Campo de entrada ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: _ChatInput(controller: _inputCtrl, onEnviar: _enviar),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Cabecera del modal ───────────────────────────────────────────────────────
class _ChatModalHeader extends StatelessWidget {
  final VoidCallback onNuevoChat;
  final VoidCallback onCerrar;

  const _ChatModalHeader({required this.onNuevoChat, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle visual
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Barra de título
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
          child: Row(
            children: [
              // Avatar del bot
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente Musilux',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF4ADE80),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'En línea',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Nuevo chat
              IconButton(
                icon: const Icon(Icons.add_comment_rounded),
                color: AppColors.textSecondary,
                tooltip: 'Nueva conversación',
                onPressed: onNuevoChat,
              ),
              // Cerrar
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                color: AppColors.textSecondary,
                tooltip: 'Cerrar',
                onPressed: onCerrar,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

// ─── Pantalla de bienvenida con sugerencias ───────────────────────────────────
class _ChatBienvenida extends StatelessWidget {
  final Future<void> Function(String) onSugerencia;
  const _ChatBienvenida({required this.onSugerencia});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Hola! Soy el asistente de Musilux',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pregúntame sobre productos musicales,\nel estado de tus pedidos o soporte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                      '¿Qué guitarras tienen?',
                      '¿Cómo va mi pedido?',
                      'Información sobre teclados',
                      'Necesito soporte',
                    ]
                    .map(
                      (texto) => ActionChip(
                        label: Text(
                          texto,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        backgroundColor: AppColors.primaryLight,
                        side: const BorderSide(
                          color: AppColors.primaryPurple,
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => onSugerencia(texto),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Burbuja de mensaje ───────────────────────────────────────────────────────
class _BurbujaMensaje extends StatelessWidget {
  final ChatMessage mensaje;
  const _BurbujaMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;
    final maxW = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: esUsuario
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esUsuario) ...[_BotBubbleAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: esUsuario
                      ? AppColors.primaryPurple
                      : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(esUsuario ? 18 : 4),
                    bottomRight: Radius.circular(esUsuario ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  mensaje.contenido,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: esUsuario ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (esUsuario) ...[const SizedBox(width: 8), _UserBubbleAvatar()],
        ],
      ),
    );
  }
}

class _BotBubbleAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1E1B2E), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 15),
  );
}

class _UserBubbleAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      gradient: AppColors.heroGradient,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 15),
  );
}

// ─── Indicador "escribiendo..." ───────────────────────────────────────────────
class _TypingIndicatorInline extends StatefulWidget {
  const _TypingIndicatorInline();

  @override
  State<_TypingIndicatorInline> createState() => _TypingIndicatorInlineState();
}

class _TypingIndicatorInlineState extends State<_TypingIndicatorInline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BotBubbleAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context2, _) {
                    final t = (_ctrl.value - i * 0.25).clamp(0.0, 1.0);
                    final opacity = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(
                      0.3,
                      1.0,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Campo de entrada del chat ────────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;

  const _ChatInput({required this.controller, required this.onEnviar});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                enabled: !chat.enviando,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje...',
                  hintStyle: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 13.5,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onEnviar(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: chat.enviando
                  ? AppColors.textDisabled
                  : AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: chat.enviando ? null : onEnviar,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: chat.enviando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
