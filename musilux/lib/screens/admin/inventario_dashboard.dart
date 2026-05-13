import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_router.dart';
import '../../theme/colors.dart';
import '../../widgets/rol_guard.dart';

/// Dashboard de inventario para admin_inventario y superadmin.
/// Redirige al panel existente de AdminProductsScreen preservando
/// toda la funcionalidad CRUD ya implementada.
class InventarioDashboard extends StatelessWidget {
  const InventarioDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario — ${auth.usuario?.nombres ?? ''}'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login, (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Productos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administra el catálogo completo de productos, precios y stock.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Botón principal — usa el panel ya existente
            RolGuard(
              permiso: 'productos.crear',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Abrir Panel de Productos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.adminProducts),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estadísticas rápidas (placeholder)
            _StatCard(
              icon: Icons.music_note_outlined,
              label: 'Ir al catálogo',
              sublabel: 'Ver productos como cliente',
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, AppRoutes.catalogoPublico),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        subtitle: Text(sublabel),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
