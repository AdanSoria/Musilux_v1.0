import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../api_constants.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';

class PedidoDetailScreen extends StatefulWidget {
  final String pedidoId;

  const PedidoDetailScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetailScreen> createState() => _PedidoDetailScreenState();
}

class _PedidoDetailScreenState extends State<PedidoDetailScreen> {
  Map<String, dynamic>? pedido;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPedido();
  }

  Future<void> _loadPedido() async {
    setState(() => loading = true);
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      if (token == null) {
        setState(() {
          pedido = null;
          loading = false;
        });
        return;
      }

      final resp = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pedidos/mis/${widget.pedidoId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          pedido = body;
        });
      } else {
        setState(() {
          pedido = null;
        });
      }
    } catch (_) {
      setState(() {
        pedido = null;
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 800;
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildMainColumn()),
                            const SizedBox(width: 12),
                            SizedBox(width: 320, child: _buildSideTotalBox()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainColumn(),
                              const SizedBox(height: 12),
                              _buildSideTotalBox(),
                            ],
                          ),
                        );
                },
              ),
            ),
    );
  }

  Widget _buildMainColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildTimeline(),
        const SizedBox(height: 18),
        _buildItemsList(),
      ],
    );
  }

  Widget _buildHeader() {
    final estado = pedido?['estado'] ?? 'desconocido';
    final creado = pedido?['creado_en'] ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${pedido?['id']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Creado: $creado',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        Chip(
          label: Text(estado.toString().toUpperCase()),
          backgroundColor: AppColors.primaryPurple.withOpacity(0.12),
          labelStyle: TextStyle(
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    // simple visual timeline placeholder for states
    final estado = pedido?['estado'] ?? 'creado';
    final steps = ['creado', 'confirmado', 'enviado', 'entregado'];
    return Row(
      children: steps.map((s) {
        final active =
            steps.indexOf(s) <=
            (steps.indexOf(estado) >= 0 ? steps.indexOf(estado) : 0);
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: active
                    ? AppColors.primaryPurple
                    : Colors.grey[300],
                child: active
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 6),
              Text(
                s,
                style: TextStyle(
                  color: active ? AppColors.primaryPurple : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemsList() {
    final items = pedido?['items'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map((it) => _buildItemRow(it)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic it) {
    final imagen = it['imagen_producto'];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      leading: imagen != null
          ? Image.network(imagen, width: 64, height: 64, fit: BoxFit.cover)
          : Container(width: 64, height: 64, color: Colors.grey[200]),
      title: Text(it['nombre_producto'] ?? ''),
      subtitle: Text(
        'Cantidad: ${it['cantidad']} • Precio unitario: \$${(it['precio_unitario'] ?? 0).toStringAsFixed(2)}',
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$${(it['cantidad'] * (it['precio_unitario'] ?? 0)).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (it.containsKey('stock'))
            Text(
              'Stock: ${it['stock'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildSideTotalBox() {
    final subtotal = (pedido?['subtotal'] ?? 0).toDouble();
    final impuestos = (pedido?['impuestos'] ?? 0).toDouble();
    final total = (pedido?['total'] ?? 0).toDouble();
    final direccion = pedido?['direccion_envio'] ?? '';
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Subtotal (sin IVA)',
              '\$${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Impuestos (16 %) — incluido',
              '\$${impuestos.toStringAsFixed(2)}',
            ),
            const Divider(height: 20),
            _buildSummaryRow(
              'Total',
              '\$${total.toStringAsFixed(2)}',
              bold: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dirección de envío',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(direccion.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              onPressed: () async {
                // Comprar nuevamente: añadir todos los items al carrito y navegar
                final items = pedido?['items'] as List? ?? [];
                final cart = Provider.of<CartProvider>(context, listen: false);
                final List<String> errors = [];

                for (final it in items) {
                  final productoId = (it['id_producto']?.toString() ?? '');
                  final nombre = it['nombre_producto']?.toString() ?? '';
                  final precio = (it['precio_unitario'] is num)
                      ? (it['precio_unitario'] as num).toDouble()
                      : double.tryParse('${it['precio_unitario']}') ?? 0.0;
                  final cantidad = (it['cantidad'] is int)
                      ? it['cantidad'] as int
                      : int.tryParse('${it['cantidad']}') ?? 1;
                  final imagenUrl = it['imagen_producto']?.toString() ?? '';
                  final stock = it.containsKey('stock') && it['stock'] != null
                      ? (it['stock'] as int)
                      : 10;

                  try {
                    final result = cart.agregarProducto(
                      productoId: productoId,
                      nombre: nombre,
                      precio: precio,
                      imagenUrl: imagenUrl,
                      stockDisponible: stock,
                      cantidad: cantidad,
                    );
                    if (result != CartAddResult.exito) {
                      // Mapear mensajes simples para el usuario
                      if (result == CartAddResult.sinStock) {
                        errors.add('Sin stock: $nombre');
                      } else if (result == CartAddResult.limiteNegocio) {
                        errors.add('Límite por pedido alcanzado: $nombre');
                      } else {
                        errors.add('No se pudo agregar: $nombre');
                      }
                    }
                  } catch (e) {
                    errors.add('Error al agregar ${nombre}: $e');
                  }
                }

                if (errors.isNotEmpty) {
                  final msg = errors.join('\n');
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                  return;
                }

                try {
                  Navigator.pushNamed(context, '/carrito');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error navegando al carrito: $e')),
                  );
                }
              },
              child: const Text(
                'Comprar nuevamente',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
