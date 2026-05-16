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

class SoporteDashboard extends StatefulWidget {
  const SoporteDashboard({super.key});

  @override
  State<SoporteDashboard> createState() => _SoporteDashboardState();
}

class _SoporteDashboardState extends State<SoporteDashboard> {
  List<dynamic> _tickets = [];
  bool _cargando = true;
  String? _error;

  // Colores por estado de ticket
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'abierto':    return Colors.red;
      case 'en_proceso': return Colors.orange;
      case 'resuelto':   return Colors.green;
      case 'cerrado':    return Colors.grey;
      default:           return Colors.blueGrey;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarTickets();
  }

  Future<void> _cargarTickets() async {
    setState(() { _cargando = true; _error = null; });

    final token = await AuthService().getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/tickets'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _tickets = data['data'] ?? []);
      } else if (response.statusCode == 403) {
        setState(() => _error = 'Sin permiso para ver tickets.');
      } else {
        setState(() => _error = 'Error al cargar tickets.');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(String ticketId, String estadoActual) async {
    const estados = ['abierto', 'en_proceso', 'resuelto', 'cerrado'];
    final seleccionado = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Cambiar estado'),
        children: estados
            .map(
              (e) => SimpleDialogOption(
                child: Text(e),
                onPressed: () => Navigator.pop(context, e),
              ),
            )
            .toList(),
      ),
    );

    if (seleccionado == null || seleccionado == estadoActual) return;

    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/tickets/$ticketId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'estado': seleccionado}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      _cargarTickets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Soporte — ${auth.usuario?.nombres ?? ''}'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTickets,
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargarTickets, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_tickets.isEmpty) {
      return const Center(
        child: Text('No hay tickets abiertos.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, i) {
          final t = _tickets[i];
          final estado = t['estado'] ?? 'abierto';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                Icons.support_agent,
                color: _colorEstado(estado),
              ),
              title: Text(t['asunto'] ?? 'Sin asunto'),
              subtitle: Text(
                '${t['nombres'] ?? ''} ${t['apellidos'] ?? ''} · $estado',
              ),
              trailing: RolGuard(
                permiso: 'tickets.actualizar',
                child: TextButton(
                  onPressed: () => _cambiarEstado(
                    t['id'].toString(),
                    estado,
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(color: _colorEstado(estado)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
