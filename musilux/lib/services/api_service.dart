import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../api_constants.dart';

class ApiService {
  final String _baseUrl = ApiConstants.baseUrl;

  /// Fetch products with optional category, search and pagination.
  ///
  /// Params supported by the backend (assumed):
  /// - category: slug or id of the category
  /// - search: free-text search across product name/description
  /// - page / per_page: pagination controls
  Future<List<Product>> fetchProducts({
    String? category,
    String? search,
    int? page,
    int? perPage,
  }) async {
    // Build query parameters map only with non-null entries
    final Map<String, String> queryParams = {};
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    final Uri uri = Uri.parse(
      '$_baseUrl/products',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // La API de Laravel envuelve la data en una clave "data" por defecto en los Resources.
        final List<dynamic> productData = json.decode(response.body)['data'];

        return productData.map((item) {
          try {
            return Product.fromJson(item);
          } catch (e) {
            print('Error parseando producto: $item');
            print('Error específico: $e');
            rethrow; // Re-lanzamos para ver el error en consola
          }
        }).toList();
      } else {
        // Log del error para facilitar el debugging.
        print('Error en la petición: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        throw Exception('Falló al cargar los productos');
      }
    } catch (e) {
      // Captura errores de conexión o parsing.
      print('Error de conexión o al procesar la respuesta: $e');
      throw Exception(
        'No se pudo conectar al servidor o procesar la respuesta.',
      );
    }
  }

  Future<Product> fetchProductById(String id) async {
    final String url = '$_baseUrl/products/$id';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // El resource de detalle también envuelve la respuesta en "data".
        final dynamic productData = json.decode(response.body)['data'];
        return Product.fromJson(productData);
      } else {
        print('Error en la petición: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        throw Exception('Falló al cargar el producto con id $id');
      }
    } catch (e) {
      print('Error de conexión o al procesar la respuesta: $e');
      throw Exception(
        'No se pudo conectar al servidor o procesar la respuesta.',
      );
    }
  }

  // --- MÉTODOS CRUD PARA ADMIN ---

  // Crear producto (POST)
  Future<bool> createProduct(Product product) async {
    final String url = '$_baseUrl/products';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(product.toJson()),
      );

      // 201 Created es el standard
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      print('Error al crear: ${response.body}');
      return false;
    } catch (e) {
      print('Error createProduct: $e');
      return false;
    }
  }

  // Actualizar producto (PUT)
  Future<bool> updateProduct(String id, Product product) async {
    final String url = '$_baseUrl/products/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(product.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updateProduct: $e');
      return false;
    }
  }

  Future<List<Product>> fetchRelatedProducts(String productId) async {
    final url = '$_baseUrl/products/$productId/related';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Eliminar producto (DELETE)
  Future<bool> deleteProduct(String id) async {
    final String url = '$_baseUrl/products/$id';
    try {
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleteProduct: $e');
      return false;
    }
  }
}
