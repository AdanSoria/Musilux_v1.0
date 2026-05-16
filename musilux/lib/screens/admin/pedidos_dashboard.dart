import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../api_constants.dart';
import '../../core/app_router.dart';
import '../../theme/colors.dart';
import '../../widgets/rol_guard.dart';

class PedidosDashboard extends StatefulWidget {
  const PedidosDashboard({super.key});

  @override
  State<PedidosDashboard> createState() => _PedidosDashboardState();
}

class _PedidosDashboardState extends State<PedidosDashboard> {
  List<dynamic> _pedidos = [];
  List<dynamic> _pedidosOriginal = [];
  bool _cargando = true;
  String? _error;
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _facturaController = TextEditingController();
  String _textoBusqueda = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  static const List<String> _estados = [
    'pendiente',
    'confirmado',
    'en_preparacion',
    'enviado',
    'entregado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _facturaController.dispose();
    super.dispose();
  }

  Future<void> _mostrarDialogoFactura() async {
    _facturaController.text = '';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Facturar pedido'),
        content: TextField(
          controller: _facturaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número de pedido',
            hintText: 'Ingrese el ID del pedido a facturar',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_facturaController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Facturar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      _facturarPedido(_facturaController.text.trim());
    }
  }

  void _facturarPedido(String pedidoId) async {
    final pedidoEncontrado = _pedidosOriginal
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (pedido) => pedido != null && pedido['id']?.toString() == pedidoId,
          orElse: () => null,
        );

    if (pedidoEncontrado == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el pedido #$pedidoId.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Generar PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Factura - Pedido #$pedidoId',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Usuario: ${pedidoEncontrado['id_usuario']?.toString() ?? 'N/A'}',
            ),
            pw.Text(
              'Estado: ${pedidoEncontrado['estado']?.toString() ?? 'N/A'}',
            ),
            pw.Text(
              'Subtotal: ${_formatMoney(pedidoEncontrado['subtotal'] ?? pedidoEncontrado['monto_subtotal'])}',
            ),
            pw.Text(
              'Costo envío: ${_formatMoney(pedidoEncontrado['costo_envio'] ?? pedidoEncontrado['shipping_cost'])}',
            ),
            pw.Text(
              'Monto total: ${_formatMoney(pedidoEncontrado['monto_total'] ?? pedidoEncontrado['total'])}',
            ),
            pw.Text(
              'Dirección envío: ${pedidoEncontrado['id_direccion_envio']?.toString() ?? pedidoEncontrado['direccion_envio']?.toString() ?? 'N/A'}',
            ),
            pw.Text(
              'Intento pago: ${pedidoEncontrado['id_intento_pago']?.toString() ?? 'N/A'}',
            ),
            pw.Text(
              'Creado en: ${_formatDate(pedidoEncontrado['creado_en'] ?? pedidoEncontrado['created_at'])}',
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Productos:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ..._buildPdfItems(pedidoEncontrado['items'] as List<dynamic>?),
          ],
        ),
      ),
    );

    // Compartir/descargar PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'factura_pedido_$pedidoId.pdf',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Factura creada y descargada para pedido #$pedidoId'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  List<pw.Widget> _buildPdfItems(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return [pw.Text('No hay artículos')];
    }

    return items.map((item) {
      final nombre =
          item['nombre_producto']?.toString() ??
          item['nombre']?.toString() ??
          'Producto desconocido';
      final cantidad =
          item['cantidad']?.toString() ?? item['qty']?.toString() ?? 'N/A';
      return pw.Text('• $nombre x $cantidad');
    }).toList();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final token = await AuthService().getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/pedidos'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pedidos = data['data'] ?? [];
        setState(() {
          _pedidosOriginal = List<dynamic>.from(pedidos);
          _aplicarFiltro();
        });
      } else if (response.statusCode == 403) {
        setState(() => _error = 'Sin permiso para ver pedidos.');
      } else {
        setState(() => _error = 'Error al cargar pedidos.');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(String pedidoId, String estadoActual) async {
    final seleccionado = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Cambiar estado'),
        children: _estados
            .map(
              (estado) => SimpleDialogOption(
                child: Text(estado),
                onPressed: () => Navigator.pop(context, estado),
              ),
            )
            .toList(),
      ),
    );

    if (seleccionado == null || seleccionado == estadoActual) return;

    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/pedidos/$pedidoId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'estado': seleccionado}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await _cargarPedidos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$seleccionado"'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMoney(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      return '\$${value.toStringAsFixed(2)}';
    }
    final parsed = double.tryParse(value.toString());
    if (parsed != null) {
      return '\$${parsed.toStringAsFixed(2)}';
    }
    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) {
      return parsed.toLocal().toString();
    }
    return value.toString();
  }

  dynamic _getIvaValue(Map<String, dynamic> pedido) {
    final ivaValue =
        pedido['impuestos'] ??
        pedido['iva'] ??
        pedido['tax'] ??
        pedido['taxes'];
    if (ivaValue != null) {
      return ivaValue;
    }

    final subtotal = double.tryParse(
      (pedido['subtotal'] ?? pedido['monto_subtotal'])?.toString() ?? '',
    );
    final total = double.tryParse(
      (pedido['monto_total'] ?? pedido['total'])?.toString() ?? '',
    );
    if (subtotal == null || total == null) return null;

    final shipping = double.tryParse(
      (pedido['costo_envio'] ?? pedido['shipping_cost'])?.toString() ?? '',
    );
    final iva = shipping != null
        ? total - subtotal - shipping
        : total - subtotal;

    return iva.isFinite && iva >= 0 ? iva : null;
  }

  DateTime? _parsePedidoDate(Map<String, dynamic> pedido) {
    final dateValue = pedido['creado_en'] ?? pedido['created_at'];
    if (dateValue == null) return null;
    return DateTime.tryParse(dateValue.toString());
  }

  void _aplicarFiltro() {
    final criterio = _textoBusqueda.trim().toLowerCase();
    setState(() {
      _pedidos = _pedidosOriginal.where((element) {
        final pedido = element as Map<String, dynamic>;
        final idTexto = pedido['id']?.toString().toLowerCase() ?? '';
        final fechaPedido = _parsePedidoDate(pedido);

        final cumpleId = criterio.isEmpty || idTexto.contains(criterio);
        final cumpleFechaInicio =
            _fechaInicio == null ||
            (fechaPedido != null && !fechaPedido.isBefore(_fechaInicio!));
        final cumpleFechaFin =
            _fechaFin == null ||
            (fechaPedido != null && !fechaPedido.isAfter(_fechaFin!));

        return cumpleId && cumpleFechaInicio && cumpleFechaFin;
      }).toList();
    });
  }

  Future<void> _copiarNumeroPedido(String pedidoId) async {
    await Clipboard.setData(ClipboardData(text: pedidoId));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número de pedido #$pedidoId copiado al portapapeles'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Future<void> _selectFechaInicio() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
        if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
          _fechaFin = _fechaInicio;
        }
      });
      _aplicarFiltro();
    }
  }

  Future<void> _selectFechaFin() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? _fechaInicio ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
        if (_fechaInicio != null && _fechaInicio!.isAfter(_fechaFin!)) {
          _fechaInicio = _fechaFin;
        }
      });
      _aplicarFiltro();
    }
  }

  void _clearFilters() {
    setState(() {
      _textoBusqueda = '';
      _fechaInicio = null;
      _fechaFin = null;
      _busquedaController.clear();
    });
    _aplicarFiltro();
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return _buildField('Productos', 'No hay artículos');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final nombre =
                item['nombre_producto']?.toString() ??
                item['nombre']?.toString() ??
                'Producto desconocido';
            final cantidad =
                item['cantidad']?.toString() ??
                item['qty']?.toString() ??
                'N/A';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $nombre x $cantidad'),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Pedidos — ${auth.usuario?.nombres ?? ''}'),
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
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoFactura,
        icon: const Icon(Icons.receipt_long),
        label: const Text('Factura'),
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarPedidos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pedidos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarPedidos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            const SizedBox(height: 120),
            const Center(
              child: Text(
                'No se encontraron pedidos con los filtros aplicados.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidos.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilters();
          }
          final pedido = _pedidos[index - 1] as Map<String, dynamic>;
          final estado = pedido['estado']?.toString() ?? 'Sin estado';
          final id = pedido['id']?.toString() ?? 'N/A';

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: Text('Pedido #$id'),
              subtitle: Text(
                '$estado · Total: ${_formatMoney(pedido['monto_total'] ?? pedido['total'])}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Número de pedido: #$id',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copiar número de pedido',
                        onPressed: () => _copiarNumeroPedido(id),
                      ),
                    ],
                  ),
                ),
                _buildField(
                  'Usuario',
                  pedido['id_usuario']?.toString() ?? 'N/A',
                ),
                _buildField('Estado', estado),
                _buildField(
                  'Subtotal',
                  _formatMoney(pedido['subtotal'] ?? pedido['monto_subtotal']),
                ),
                _buildField(
                  'Costo envío',
                  _formatMoney(
                    pedido['costo_envio'] ?? pedido['shipping_cost'],
                  ),
                ),
                _buildField('IVA', _formatMoney(_getIvaValue(pedido))),
                _buildField(
                  'Monto total',
                  _formatMoney(pedido['monto_total'] ?? pedido['total']),
                ),
                _buildField(
                  'Dirección envío',
                  pedido['id_direccion_envio']?.toString() ??
                      pedido['direccion_envio']?.toString() ??
                      'N/A',
                ),
                _buildField(
                  'Intento pago',
                  pedido['id_intento_pago']?.toString() ?? 'N/A',
                ),
                _buildItemsSection(pedido['items'] as List<dynamic>?),
                _buildField(
                  'Creado en',
                  _formatDate(pedido['creado_en'] ?? pedido['created_at']),
                ),
                _buildField(
                  'Actualizado en',
                  _formatDate(pedido['actualizado_en'] ?? pedido['updated_at']),
                ),
                const SizedBox(height: 12),
                RolGuard(
                  permiso: 'pedidos.actualizar',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sync_alt),
                      label: const Text('Cambiar estado'),
                      onPressed: () {
                        if (pedido['id'] != null) {
                          _cambiarEstado(pedido['id'].toString(), estado);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtros de búsqueda',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _busquedaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de pedido',
                hintText: 'Buscar por ID de pedido',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _textoBusqueda = value;
                _aplicarFiltro();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaInicio == null
                          ? 'Fecha inicio'
                          : 'Desde: ${_fechaInicio!.toLocal().toString().split(' ').first}',
                    ),
                    onPressed: _selectFechaInicio,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaFin == null
                          ? 'Fecha fin'
                          : 'Hasta: ${_fechaFin!.toLocal().toString().split(' ').first}',
                    ),
                    onPressed: _selectFechaFin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                child: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
