import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_model.dart';
import '../../../api_constants.dart';

class ProductService {
  // Usa ApiConstants para consistencia con el resto de la app.
  // Bug anterior: apuntaba a /api/productos (ruta inexistente → 404).
  String get baseUrl => '${ApiConstants.baseUrl}/products';

  // Token de autenticación (se asigna desde AuthService al hacer login)
  static String? authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<List<ProductModel>> getProducts() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Laravel Resources envuelven la lista en una clave "data"
      final decoded = jsonDecode(response.body);
      final List<dynamic> body = decoded is Map ? decoded['data'] : decoded;
      return body.map((dynamic item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar productos: ${response.statusCode}');
    }
  }

  Future<bool> createProduct(ProductModel product) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    );
    // Aceptamos 200 y 201 por compatibilidad con Laravel Resource (retorna 200 por defecto)
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> updateProduct(ProductModel product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${product.id}'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
