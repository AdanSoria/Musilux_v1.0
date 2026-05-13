import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_router.dart';
import '../../theme/colors.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  static const _modulos = [
    _Modulo(
      icon: Icons.inventory_2_outlined,
      label: 'Inventario',
      sublabel: 'Productos y stock',
      color: Colors.indigo,
      route: AppRoutes.inventarioDashboard,
    ),
    _Modulo(
      icon: Icons.receipt_long_outlined,
      label: 'Pedidos',
      sublabel: 'Gestión de órdenes',
      color: Colors.orange,
      route: AppRoutes.pedidosDashboard,
    ),
    _Modulo(
      icon: Icons.people_outlined,
      label: 'Usuarios',
      sublabel: 'Cuentas y roles',
      color: Colors.teal,
      route: AppRoutes.usuariosDashboard,
    ),
    _Modulo(
      icon: Icons.bar_chart_outlined,
      label: 'Ventas',
      sublabel: 'Reportes y métricas',
      color: Colors.green,
      route: AppRoutes.ventasDashboard,
    ),
    _Modulo(
      icon: Icons.support_agent_outlined,
      label: 'Soporte',
      sublabel: 'Tickets de ayuda',
      color: Colors.blue,
      route: AppRoutes.soporteDashboard,
    ),
    _Modulo(
      icon: Icons.admin_panel_settings_outlined,
      label: 'Productos',
      sublabel: 'Panel de administración',
      color: Colors.deepPurple,
      route: AppRoutes.adminProducts,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.usuario?.nombres ?? '';

    return Scaffold(
      backgroundColor: AppColors.headerBg,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Ver tienda',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.catalogoPublico),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryPurple.withOpacity(0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryPurple,
                  radius: 24,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, $nombre',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Título de sección
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Módulos disponibles',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Grid de módulos
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _modulos.length,
              itemBuilder: (context, i) => _ModuloCard(modulo: _modulos[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// Datos inmutables de cada módulo — sin capturar contexto.
class _Modulo {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final String route;

  const _Modulo({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.route,
  });
}

class _ModuloCard extends StatelessWidget {
  final _Modulo modulo;

  const _ModuloCard({required this.modulo});

  @override
  Widget build(BuildContext context) {
    // Navegación desde el contexto propio del card — nunca desde un contexto capturado.
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pushNamed(modulo.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: modulo.color.withOpacity(0.12),
                radius: 28,
                child: Icon(modulo.icon, color: modulo.color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                modulo.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: modulo.color,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                modulo.sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
