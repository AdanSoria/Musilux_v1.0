import 'dart:convert';

/// Representa un producto dentro del carrito de compras.
/// [precioAlAgregar] congela el precio en el momento de la adición —
/// si el backend lo modifica, se detecta y se notifica al usuario.
class CartItem {
  final String productoId;
  final String nombre;
  final double precioUnitario;   // precio actual (puede cambiar)
  final double precioAlAgregar;  // precio congelado al momento de agregar
  final String imagenUrl;
  final int stockDisponible;
  int cantidad;

  CartItem({
    required this.productoId,
    required this.nombre,
    required this.precioUnitario,
    required this.precioAlAgregar,
    required this.imagenUrl,
    required this.stockDisponible,
    this.cantidad = 1,
  });

  // ── Cálculos por línea ────────────────────────────────────────────────────
  double get subtotalLinea => precioUnitario * cantidad;

  /// true si el precio cambió desde que se agregó al carrito
  bool get precioModificado =>
      (precioUnitario - precioAlAgregar).abs() > 0.001;

  // ── Serialización ─────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'productoId':     productoId,
        'nombre':         nombre,
        'precioUnitario': precioUnitario,
        'precioAlAgregar':precioAlAgregar,
        'imagenUrl':      imagenUrl,
        'stockDisponible':stockDisponible,
        'cantidad':       cantidad,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productoId:      json['productoId']      as String,
        nombre:          json['nombre']           as String,
        precioUnitario:  (json['precioUnitario']  as num).toDouble(),
        precioAlAgregar: (json['precioAlAgregar'] as num).toDouble(),
        imagenUrl:       json['imagenUrl']        as String,
        stockDisponible: (json['stockDisponible'] as num).toInt(),
        cantidad:        (json['cantidad']        as num).toInt(),
      );

  /// Crea una copia con campos modificados.
  CartItem copyWith({
    double? precioUnitario,
    int? cantidad,
    int? stockDisponible,
  }) =>
      CartItem(
        productoId:      productoId,
        nombre:          nombre,
        precioUnitario:  precioUnitario  ?? this.precioUnitario,
        precioAlAgregar: precioAlAgregar,
        imagenUrl:       imagenUrl,
        stockDisponible: stockDisponible ?? this.stockDisponible,
        cantidad:        cantidad        ?? this.cantidad,
      );

  static String encodeList(List<CartItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CartItem> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
