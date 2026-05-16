import 'package:flutter_test/flutter_test.dart';
import 'package:musilux/models/cart_item.dart';

CartItem makeItem({
  String id = 'p1',
  String nombre = 'Guitarra',
  double precio = 100.0,
  double? precioAlAgregar,
  int cantidad = 1,
  int stock = 10,
}) =>
    CartItem(
      productoId: id,
      nombre: nombre,
      precioUnitario: precio,
      precioAlAgregar: precioAlAgregar ?? precio,
      imagenUrl: 'https://img.com/test.jpg',
      stockDisponible: stock,
      cantidad: cantidad,
    );

void main() {
  group('CartItem.subtotalLinea', () {
    test('calcula precio unitario × cantidad', () {
      expect(makeItem(precio: 250.0, cantidad: 3).subtotalLinea, 750.0);
    });

    test('es igual al precio cuando cantidad es 1', () {
      expect(makeItem(precio: 500.0).subtotalLinea, 500.0);
    });

    test('es cero cuando precio es cero', () {
      expect(makeItem(precio: 0.0, cantidad: 5).subtotalLinea, 0.0);
    });
  });

  group('CartItem.precioModificado', () {
    test('es false cuando el precio no cambió', () {
      expect(
          makeItem(precio: 100.0, precioAlAgregar: 100.0).precioModificado,
          false);
    });

    test('es true cuando el precio subió', () {
      expect(
          makeItem(precio: 120.0, precioAlAgregar: 100.0).precioModificado,
          true);
    });

    test('es true cuando el precio bajó', () {
      expect(
          makeItem(precio: 80.0, precioAlAgregar: 100.0).precioModificado,
          true);
    });

    test('tolera diferencias menores a 0.001 (ruido de punto flotante)', () {
      expect(
          makeItem(precio: 100.0001, precioAlAgregar: 100.0).precioModificado,
          false);
    });
  });

  group('CartItem serialización', () {
    test('toJson y fromJson hacen round-trip completo', () {
      final original = makeItem(precio: 350.0, cantidad: 2);
      final decoded = CartItem.fromJson(original.toJson());
      expect(decoded.productoId, original.productoId);
      expect(decoded.nombre, original.nombre);
      expect(decoded.precioUnitario, original.precioUnitario);
      expect(decoded.precioAlAgregar, original.precioAlAgregar);
      expect(decoded.cantidad, original.cantidad);
      expect(decoded.stockDisponible, original.stockDisponible);
      expect(decoded.imagenUrl, original.imagenUrl);
    });

    test('encodeList y decodeList hacen round-trip de múltiples items', () {
      final items = [
        makeItem(id: 'p1', precio: 100.0, cantidad: 2),
        makeItem(id: 'p2', nombre: 'Bajo', precio: 200.0, cantidad: 1),
      ];
      final decoded = CartItem.decodeList(CartItem.encodeList(items));
      expect(decoded.length, 2);
      expect(decoded[0].productoId, 'p1');
      expect(decoded[0].cantidad, 2);
      expect(decoded[1].productoId, 'p2');
      expect(decoded[1].precioUnitario, 200.0);
    });

    test('encodeList de lista vacía se puede decodificar', () {
      final decoded = CartItem.decodeList(CartItem.encodeList([]));
      expect(decoded, isEmpty);
    });
  });

  group('CartItem.copyWith', () {
    test('actualiza precioUnitario manteniendo otros campos', () {
      final item = makeItem(precio: 100.0, cantidad: 3);
      final updated = item.copyWith(precioUnitario: 150.0);
      expect(updated.precioUnitario, 150.0);
      expect(updated.cantidad, 3);
      expect(updated.precioAlAgregar, 100.0);
      expect(updated.productoId, 'p1');
      expect(updated.nombre, 'Guitarra');
    });

    test('actualiza cantidad manteniendo precio', () {
      final item = makeItem(precio: 100.0, cantidad: 1);
      final updated = item.copyWith(cantidad: 5);
      expect(updated.cantidad, 5);
      expect(updated.precioUnitario, 100.0);
      expect(updated.precioAlAgregar, 100.0);
    });

    test('actualiza stockDisponible manteniendo otros campos', () {
      final item = makeItem(stock: 10);
      final updated = item.copyWith(stockDisponible: 3);
      expect(updated.stockDisponible, 3);
      expect(updated.nombre, item.nombre);
      expect(updated.precioUnitario, item.precioUnitario);
    });

    test('sin argumentos devuelve copia con valores idénticos', () {
      final item = makeItem(precio: 100.0, cantidad: 2);
      final copy = item.copyWith();
      expect(copy.precioUnitario, 100.0);
      expect(copy.cantidad, 2);
      expect(copy.productoId, item.productoId);
    });

    test('precioAlAgregar nunca cambia en copyWith', () {
      final item = makeItem(precio: 100.0, precioAlAgregar: 90.0);
      final updated = item.copyWith(precioUnitario: 200.0);
      expect(updated.precioAlAgregar, 90.0);
    });
  });
}
