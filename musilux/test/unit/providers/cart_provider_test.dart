import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musilux/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CartProvider makeCart() => CartProvider();

  void addItem(
    CartProvider cart, {
    String id = 'p1',
    String nombre = 'Guitarra',
    double precio = 500.0,
    int stock = 10,
    int cantidad = 1,
  }) {
    cart.agregarProducto(
      productoId: id,
      nombre: nombre,
      precio: precio,
      imagenUrl: 'https://img.com/test.jpg',
      stockDisponible: stock,
      cantidad: cantidad,
    );
  }

  group('CartProvider — estado inicial', () {
    test('carrito inicia vacío', () {
      final cart = makeCart();
      expect(cart.isEmpty, true);
      expect(cart.items, isEmpty);
      expect(cart.total, 0.0);
      expect(cart.totalUnidades, 0);
    });
  });

  group('CartProvider.agregarProducto', () {
    test('agrega item con stock disponible', () {
      final cart = makeCart();
      final result = cart.agregarProducto(
        productoId: 'p1',
        nombre: 'Guitarra',
        precio: 500.0,
        imagenUrl: '',
        stockDisponible: 5,
      );
      expect(result, CartAddResult.exito);
      expect(cart.items.length, 1);
      expect(cart.items.first.nombre, 'Guitarra');
      expect(cart.items.first.precioUnitario, 500.0);
    });

    test('retorna sinStock cuando stock es 0', () {
      final cart = makeCart();
      final result = cart.agregarProducto(
        productoId: 'p1',
        nombre: 'Guitarra',
        precio: 500.0,
        imagenUrl: '',
        stockDisponible: 0,
      );
      expect(result, CartAddResult.sinStock);
      expect(cart.isEmpty, true);
    });

    test('retorna limiteNegocio cuando cantidad supera el máximo (10)', () {
      final cart = makeCart();
      final result = cart.agregarProducto(
        productoId: 'p1',
        nombre: 'Guitarra',
        precio: 500.0,
        imagenUrl: '',
        stockDisponible: 20,
        cantidad: 11,
      );
      expect(result, CartAddResult.limiteNegocio);
      expect(cart.isEmpty, true);
    });

    test('incrementa cantidad si el producto ya existe en el carrito', () {
      final cart = makeCart();
      addItem(cart, id: 'p1');
      addItem(cart, id: 'p1');
      expect(cart.items.length, 1);
      expect(cart.items.first.cantidad, 2);
    });

    test('agrega productos distintos como items separados', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', precio: 500.0);
      addItem(cart, id: 'p2', nombre: 'Bajo', precio: 700.0);
      expect(cart.items.length, 2);
    });

    test('retorna sinStock al agregar cuando el carrito ya tiene todo el stock', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', stock: 5, cantidad: 5);
      final result = cart.agregarProducto(
        productoId: 'p1',
        nombre: 'Guitarra',
        precio: 500.0,
        imagenUrl: '',
        stockDisponible: 5,
      );
      expect(result, CartAddResult.sinStock);
    });
  });

  group('CartProvider — cálculos monetarios', () {
    test('total es la suma de subtotales por línea', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', precio: 500.0, cantidad: 2);
      addItem(cart, id: 'p2', nombre: 'Bajo', precio: 700.0);
      expect(cart.total, closeTo(1700.0, 0.001));
    });

    test('subtotal e impuestos son coherentes con IVA 16%', () {
      final cart = makeCart();
      addItem(cart, precio: 116.0);
      expect(cart.total, closeTo(116.0, 0.001));
      expect(cart.subtotal, closeTo(100.0, 0.001));
      expect(cart.impuestos, closeTo(16.0, 0.001));
    });

    test('subtotal + impuestos == total', () {
      final cart = makeCart();
      addItem(cart, precio: 580.0, cantidad: 3);
      expect(cart.subtotal + cart.impuestos, closeTo(cart.total, 0.001));
    });

    test('totalUnidades suma cantidades de todos los items', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', cantidad: 3);
      addItem(cart, id: 'p2', nombre: 'Bajo', cantidad: 2);
      expect(cart.totalUnidades, 5);
    });
  });

  group('CartProvider.actualizarCantidad', () {
    test('actualiza cantidad correctamente', () {
      final cart = makeCart();
      addItem(cart);
      expect(cart.actualizarCantidad('p1', 5), CartUpdateResult.exito);
      expect(cart.items.first.cantidad, 5);
    });

    test('retorna noEncontrado para producto inexistente', () {
      final cart = makeCart();
      expect(cart.actualizarCantidad('nope', 3), CartUpdateResult.noEncontrado);
    });

    test('elimina item cuando cantidad es 0', () {
      final cart = makeCart();
      addItem(cart);
      expect(cart.actualizarCantidad('p1', 0), CartUpdateResult.eliminado);
      expect(cart.isEmpty, true);
    });

    test('retorna limiteStock cuando excede stock disponible', () {
      final cart = makeCart();
      addItem(cart, stock: 5);
      expect(cart.actualizarCantidad('p1', 6), CartUpdateResult.limiteStock);
      expect(cart.items.first.cantidad, 1);
    });

    test('retorna limiteNegocio cuando supera el máximo por producto', () {
      final cart = makeCart();
      addItem(cart, stock: 20);
      expect(cart.actualizarCantidad('p1', 11), CartUpdateResult.limiteNegocio);
    });
  });

  group('CartProvider.eliminarProducto', () {
    test('elimina el item indicado', () {
      final cart = makeCart();
      addItem(cart);
      cart.eliminarProducto('p1');
      expect(cart.isEmpty, true);
    });

    test('no falla si el producto no existe', () {
      final cart = makeCart();
      expect(() => cart.eliminarProducto('nope'), returnsNormally);
    });

    test('elimina solo el producto indicado sin afectar los demás', () {
      final cart = makeCart();
      addItem(cart, id: 'p1');
      addItem(cart, id: 'p2', nombre: 'Bajo');
      cart.eliminarProducto('p1');
      expect(cart.items.length, 1);
      expect(cart.items.first.productoId, 'p2');
    });
  });

  group('CartProvider.vaciarCarrito', () {
    test('deja el carrito completamente vacío', () async {
      final cart = makeCart();
      addItem(cart, id: 'p1');
      addItem(cart, id: 'p2', nombre: 'Bajo');
      await cart.vaciarCarrito();
      expect(cart.isEmpty, true);
      expect(cart.total, 0.0);
      expect(cart.totalUnidades, 0);
    });
  });

  group('CartProvider.buildOrdenPayload', () {
    test('genera la estructura correcta para el checkout', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', precio: 500.0, cantidad: 2);
      final payload = cart.buildOrdenPayload('Calle Principal 123');
      final items = payload['items'] as List;
      expect(items.length, 1);
      expect(items.first['id_producto'], 'p1');
      expect(items.first['cantidad'], 2);
      expect(payload['total'], closeTo(1000.0, 0.001));
      expect(payload['direccion_envio'], 'Calle Principal 123');
      expect(payload.containsKey('subtotal'), true);
      expect(payload.containsKey('impuestos'), true);
    });
  });

  group('CartProvider.sincronizarConBackend', () {
    test('detecta cambio de precio y actualiza el item', () {
      final cart = makeCart();
      addItem(cart, precio: 500.0);
      final alertas = cart.sincronizarConBackend([
        (id: 'p1', precio: 600.0, stock: 10),
      ]);
      expect(alertas, isNotEmpty);
      expect(alertas.first, contains('Guitarra'));
      expect(cart.items.first.precioUnitario, 600.0);
    });

    test('elimina producto cuando el stock llega a 0', () {
      final cart = makeCart();
      addItem(cart);
      final alertas = cart.sincronizarConBackend([
        (id: 'p1', precio: 500.0, stock: 0),
      ]);
      expect(alertas, isNotEmpty);
      expect(cart.isEmpty, true);
    });

    test('elimina producto que ya no existe en el backend', () {
      final cart = makeCart();
      addItem(cart);
      final alertas = cart.sincronizarConBackend([]);
      expect(alertas, isNotEmpty);
      expect(cart.isEmpty, true);
    });

    test('no genera alertas cuando no hay cambios', () {
      final cart = makeCart();
      addItem(cart, precio: 500.0, stock: 10);
      final alertas = cart.sincronizarConBackend([
        (id: 'p1', precio: 500.0, stock: 10),
      ]);
      expect(alertas, isEmpty);
    });

    test('ajusta cantidad cuando supera el nuevo stock disponible', () {
      final cart = makeCart();
      addItem(cart, stock: 10, cantidad: 8);
      final alertas = cart.sincronizarConBackend([
        (id: 'p1', precio: 500.0, stock: 3),
      ]);
      expect(alertas, isNotEmpty);
      expect(cart.items.first.cantidad, 3);
    });

    test('itemsConPrecioCambiado retorna solo items con precio modificado', () {
      final cart = makeCart();
      addItem(cart, id: 'p1', precio: 500.0);
      addItem(cart, id: 'p2', nombre: 'Bajo', precio: 700.0);
      cart.sincronizarConBackend([
        (id: 'p1', precio: 600.0, stock: 10),
        (id: 'p2', precio: 700.0, stock: 10),
      ]);
      expect(cart.itemsConPrecioCambiado.length, 1);
      expect(cart.itemsConPrecioCambiado.first.productoId, 'p1');
    });
  });
}
