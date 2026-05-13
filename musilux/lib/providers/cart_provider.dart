import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// Tasa de IVA aplicada sobre el precio final (México 16 %).
/// Nota: los precios en la base de datos y la UI incluyen IVA. Aquí calculamos
/// la porción de IVA incluida para mostrar el desglose.
const double _kIva = 0.16;

/// Máximo de unidades de un mismo producto por compra.
const int _kMaxPorProducto = 10;

/// Proveedor reactivo del carrito de compras.
/// Implementa las 5 áreas del spec:
///   1. Estado global con List<CartItem>
///   2. Operaciones atómicas (añadir, actualizar, eliminar, vaciar)
///   3. Motor de cálculos (subtotal, IVA, total)
///   4. Validaciones de stock y precio
///   5. Persistencia local + recuperación
class CartProvider extends ChangeNotifier {
  static const String _kCartKey = 'cart_items';

  final List<CartItem> _items = [];

  // ── Getters de estado ──────────────────────────────────────────────────────

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalUnidades => _items.fold(0, (sum, item) => sum + item.cantidad);

  /// Productos cuyo precio cambió desde que se agregaron al carrito.
  List<CartItem> get itemsConPrecioCambiado =>
      _items.where((i) => i.precioModificado).toList();

  // ── Motor de cálculos ──────────────────────────────────────────────────────

  // Total con IVA (suma de precios que ya incluyen IVA)
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotalLinea);

  /// Subtotal sin impuesto (base): total / (1 + IVA)
  double get subtotal => total / (1 + _kIva);

  /// Impuesto correspondiente (subtotal * IVA)
  double get impuestos => subtotal * _kIva;

  // ── Inicialización — rehidratación desde SharedPreferences ─────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCartKey);
    if (raw == null || raw.isEmpty) return;
    try {
      _items
        ..clear()
        ..addAll(CartItem.decodeList(raw));
      notifyListeners();
    } catch (_) {
      // JSON corrompido — empezar con carrito vacío
      await prefs.remove(_kCartKey);
    }

  }

  // ── Operación 1: Añadir producto ───────────────────────────────────────────

  /// Devuelve un `CartAddResult` indicando si la operación fue exitosa
  /// o por qué fue rechazada (sin stock, límite alcanzado).
  CartAddResult agregarProducto({
    required String productoId,
    required String nombre,
    required double precio,
    required String imagenUrl,
    required int stockDisponible,
    int cantidad = 1,
  }) {
    // Validación de stock
    if (stockDisponible <= 0) return CartAddResult.sinStock;

    final existente = _findById(productoId);

    if (existente != null) {
      final nuevaCantidad = existente.cantidad + cantidad;

      // Límite por stock
      if (nuevaCantidad > stockDisponible) {
        return CartAddResult.limiteStock(stockDisponible - existente.cantidad);
      }
      // Límite de negocio
      if (nuevaCantidad > _kMaxPorProducto) {
        return CartAddResult.limiteNegocio;
      }

      existente.cantidad = nuevaCantidad;
    } else {
      if (cantidad > stockDisponible)
        return CartAddResult.limiteStock(stockDisponible);
      if (cantidad > _kMaxPorProducto) return CartAddResult.limiteNegocio;

      _items.add(
        CartItem(
          productoId: productoId,
          nombre: nombre,
          precioUnitario: precio,
          precioAlAgregar: precio,
          imagenUrl: imagenUrl,
          stockDisponible: stockDisponible,
          cantidad: cantidad,
        ),
      );
    }

    _persistir();
    notifyListeners();
    // Debug: imprimir contenido actual del carrito para diagnóstico
    debugPrint(
      'CartProvider: items=${_items.map((i) => '${i.nombre}(${i.cantidad})').toList()}',
    );
    return CartAddResult.exito;
  }

  // ── Operación 2: Actualizar cantidad ───────────────────────────────────────

  /// Si [nuevaCantidad] == 0, elimina el ítem automáticamente.
  CartUpdateResult actualizarCantidad(String productoId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      eliminarProducto(productoId);
      return CartUpdateResult.eliminado;
    }

    final item = _findById(productoId);
    if (item == null) return CartUpdateResult.noEncontrado;

    if (nuevaCantidad > item.stockDisponible) {
      return CartUpdateResult.limiteStock;
    }
    if (nuevaCantidad > _kMaxPorProducto) {
      return CartUpdateResult.limiteNegocio;
    }

    item.cantidad = nuevaCantidad;
    _persistir();
    notifyListeners();
    return CartUpdateResult.exito;
  }

  // ── Operación 3: Eliminar producto ─────────────────────────────────────────

  void eliminarProducto(String productoId) {
    _items.removeWhere((i) => i.productoId == productoId);
    _persistir();
    notifyListeners();
  }

  // ── Operación 4: Vaciar carrito ────────────────────────────────────────────

  Future<void> vaciarCarrito() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCartKey);
    notifyListeners();
  }

  // ── Validación: sincronizar stock y precio desde el backend ───────────────
  /// Llamar antes del checkout para detectar cambios en precios o stock.
  /// [productosActuales] es la lista refrescada del backend.
  List<String> sincronizarConBackend(
    List<({String id, double precio, int stock})> productosActuales,
  ) {
    final alertas = <String>[];

    for (final item in List.of(_items)) {
      final actual = productosActuales
          .where((p) => p.id == item.productoId)
          .firstOrNull;

      if (actual == null) {
        _items.remove(item);
        alertas.add(
          '${item.nombre} ya no está disponible y fue eliminado del carrito.',
        );
        continue;
      }

      bool cambio = false;

      // Cambio de precio
      if ((actual.precio - item.precioUnitario).abs() > 0.001) {
        final nuevoItem = item.copyWith(precioUnitario: actual.precio);
        final idx = _items.indexOf(item);
        _items[idx] = nuevoItem;
        alertas.add(
          'El precio de ${item.nombre} cambió de '
          '\$${item.precioUnitario.toStringAsFixed(2)} a '
          '\$${actual.precio.toStringAsFixed(2)}.',
        );
        cambio = true;
      }

      // Sin stock suficiente
      if (actual.stock <= 0) {
        _items.remove(item);
        alertas.add('${item.nombre} está agotado y fue eliminado del carrito.');
        cambio = true;
      } else if (item.cantidad > actual.stock) {
        final idx = _items.indexOf(item);
        if (idx >= 0)
          _items[idx] = item.copyWith(
            cantidad: actual.stock,
            stockDisponible: actual.stock,
          );
        alertas.add(
          'La cantidad de ${item.nombre} se ajustó a ${actual.stock} (stock disponible).',
        );
        cambio = true;
      }

      if (cambio) {
        final idx = _items.indexWhere((i) => i.productoId == item.productoId);
        if (idx >= 0) {
          _items[idx] = _items[idx].copyWith(stockDisponible: actual.stock);
        }
      }
    }

    if (alertas.isNotEmpty) {
      _persistir();
      notifyListeners();
    }

    return alertas;
  }

  // ── Hand-off al Checkout ───────────────────────────────────────────────────

  /// Genera el objeto de orden listo para enviar al backend de checkout.
  Map<String, dynamic> buildOrdenPayload(String direccionEnvio) => {
    'items': _items
        .map(
          (i) => {
            'id_producto': i.productoId,
            'cantidad': i.cantidad,
            'precio_unitario': i.precioUnitario,
          },
        )
        .toList(),
    'subtotal': subtotal,
    // Enviamos 'impuestos' como la porción incluida para que el backend y UI
    // puedan mostrar el desglose. Nota: subtotal ya incluye impuestos.
    'impuestos': impuestos,
    'total': total,
    'direccion_envio': direccionEnvio,
  };

  // ── Internos ───────────────────────────────────────────────────────────────

  CartItem? _findById(String productoId) =>
      _items.where((i) => i.productoId == productoId).firstOrNull;

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCartKey, CartItem.encodeList(_items));
  }
}

// ── Tipos de resultado ────────────────────────────────────────────────────────

enum CartAddResult {
  exito,
  sinStock,
  limiteNegocio;

  static CartAddResult limiteStock(int disponibles) =>
      disponibles <= 0 ? sinStock : exito;
}

enum CartUpdateResult {
  exito,
  eliminado,
  noEncontrado,
  limiteStock,
  limiteNegocio,
}
