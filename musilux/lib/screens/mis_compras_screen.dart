import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../api_constants.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';

class MisComprasScreen extends StatefulWidget {
  const MisComprasScreen({super.key});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
  final _auth = AuthService();
  List<dynamic> _pedidos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getToken();
      if (token == null) {
        setState(() {
          _error = 'No autenticado';
          _loading = false;
        });
        return;
      }

      final resp = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pedidos/mis'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _pedidos = body['data'] ?? [];
        });
      } else {
        setState(() {
          _error = 'Error al cargar pedidos';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: RefreshIndicator(
        onRefresh: _loadPedidos,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pedidos.length,
                itemBuilder: (context, index) {
                  final p = _pedidos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/mis-compras/${p['id']}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen / composición de miniaturas
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  // Principal en la esquina superior izquierda
                                  Positioned(
                                    left: 12,
                                    top: 12,
                                    child: p['imagen'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              p['imagen'],
                                              width: 96,
                                              height: 96,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : SizedBox(width: 96, height: 96),
                                  ),
                                  // Placeholder de miniaturas (simuladas)
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: p['imagen'] != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    p['imagen'],
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '+${(p['items_count'] ?? 0) - 3}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 18),

                            // Detalles del pedido
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p['items_count']} items',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Order #${p['id']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '\$${(p['total'] ?? 0).toString()} MXN',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          final token = await _auth.getToken();
                                          if (token == null) return;
                                          final resp = await http.get(
                                            Uri.parse(
                                              '${ApiConstants.baseUrl}/pedidos/mis/${p['id']}',
                                            ),
                                            headers: {
                                              'Accept': 'application/json',
                                              'Authorization': 'Bearer $token',
                                            },
                                          );
                                          if (resp.statusCode == 200) {
                                            final detail =
                                                jsonDecode(resp.body)
                                                    as Map<String, dynamic>;
                                            final items =
                                                detail['items']
                                                    as List<dynamic>;
                                            final cart =
                                                Provider.of<CartProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            for (final it in items) {
                                              final productoId =
                                                  it['id_producto']
                                                      ?.toString() ??
                                                  '';
                                              final nombre =
                                                  it['nombre_producto']
                                                      ?.toString() ??
                                                  '';
                                              final precio =
                                                  (it['precio_unitario'] is num)
                                                  ? (it['precio_unitario']
                                                            as num)
                                                        .toDouble()
                                                  : double.tryParse(
                                                          '${it['precio_unitario']}',
                                                        ) ??
                                                        0.0;
                                              final imagen =
                                                  it['imagen_producto']
                                                      ?.toString() ??
                                                  '';
                                              final cantidad =
                                                  (it['cantidad'] is int)
                                                  ? it['cantidad'] as int
                                                  : int.tryParse(
                                                          '${it['cantidad']}',
                                                        ) ??
                                                        1;
                                              cart.agregarProducto(
                                                productoId: productoId,
                                                nombre: nombre,
                                                precio: precio,
                                                imagenUrl: imagen,
                                                stockDisponible: 10,
                                                cantidad: cantidad,
                                              );
                                            }
                                            Navigator.pushNamed(
                                              context,
                                              '/carrito',
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text('Comprar nuevamente'),
                                      ),
                                      const SizedBox(width: 12),
                                      Chip(label: Text(p['estado'] ?? '')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
