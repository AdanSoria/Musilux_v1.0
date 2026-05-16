import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../api_constants.dart';
import '../../core/app_router.dart';
import '../../theme/colors.dart';
import '../../widgets/rol_guard.dart';

class VentasDashboard extends StatefulWidget {
  const VentasDashboard({super.key});

  @override
  State<VentasDashboard> createState() => _VentasDashboardState();
}

class _VentasDashboardState extends State<VentasDashboard> {
  Map<String, dynamic>? _metricas;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() { _cargando = true; _error = null; });

    final token = await AuthService().getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/reportes/metricas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() => _metricas = jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        setState(() => _error = 'Sin permiso para ver reportes.');
      } else {
        setState(() => _error = 'Error al cargar métricas.');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas — ${auth.usuario?.nombres ?? ''}'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Ver tienda',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.catalogoPublico),
          ),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.orange.shade800)),
            ),

          const SizedBox(height: 16),

          Text(
            'Reportes & Métricas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Módulo en construcción — los datos aparecerán aquí cuando se implemente el modelo de ventas.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 24),

          RolGuard(
            permiso: 'cupones.crear',
            child: _AccionCard(
              icon: Icons.local_offer_outlined,
              label: 'Gestionar Cupones',
              sublabel: 'Crear y editar cupones de descuento',
              color: Colors.green,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Módulo de cupones en construcción.'),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          RolGuard(
            permiso: 'reportes.leer',
            child: _AccionCard(
              icon: Icons.bar_chart_outlined,
              label: 'Reporte de Ingresos',
              sublabel: 'Ver resumen de ventas por período',
              color: Colors.blue,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Módulo de reportes en construcción.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
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
        leading: Icon(icon, color: color, size: 28),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        subtitle: Text(sublabel),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
