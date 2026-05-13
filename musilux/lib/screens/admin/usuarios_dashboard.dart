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

class UsuariosDashboard extends StatefulWidget {
  const UsuariosDashboard({super.key});

  @override
  State<UsuariosDashboard> createState() => _UsuariosDashboardState();
}

class _UsuariosDashboardState extends State<UsuariosDashboard> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final token = await AuthService().getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/usuarios'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _usuarios = data['data'] ?? []);
      } else if (response.statusCode == 403) {
        setState(() => _error = 'Sin permiso para ver usuarios.');
      } else {
        setState(() => _error = 'Error al cargar usuarios.');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _suspenderUsuario(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Suspender cuenta'),
        content: Text('¿Suspender la cuenta de $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Suspender',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await AuthService().getToken();

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/usuarios/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cuenta suspendida.')));
      _cargarUsuarios();
    } else {
      final msg = jsonDecode(response.body)['message'] ?? 'Error al suspender.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios — ${auth.usuario?.nombres ?? ''}'),
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
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarUsuarios,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios registrados.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _usuarios.length,
        itemBuilder: (context, i) {
          final u = _usuarios[i];
          final activo = u['esta_activo'] ?? true;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: activo
                    ? Colors.teal.shade100
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  color: activo ? Colors.teal : Colors.grey,
                ),
              ),
              title: Text('${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['correo'] ?? ''),
                  Text(
                    (u['rol'] is Map ? u['rol']['nombre'] : u['rol']) ?? 'sin rol',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: RolGuard(
                permiso: 'usuarios.eliminar',
                child: IconButton(
                  icon: Icon(
                    activo ? Icons.block : Icons.check_circle_outline,
                    color: activo ? Colors.red : Colors.green,
                  ),
                  tooltip: activo ? 'Suspender' : 'Reactivar (manual en BD)',
                  onPressed: activo
                      ? () => _suspenderUsuario(
                          u['id'].toString(),
                          '${u['nombres']} ${u['apellidos']}',
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
