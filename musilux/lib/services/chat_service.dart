import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatService {
  static String get _base => ApiConstants.baseUrl;

  // ── Enviar mensaje y obtener respuesta ──────────────────────────────────────
  /// Devuelve un Map con 'id_sesion' (String) y 'respuesta' (String).
  Future<Map<String, String>> enviarMensaje({
    required String mensaje,
    String? idSesion,
  }) async {
    final token = await AuthService().getToken();

    final body = <String, dynamic>{'mensaje': mensaje};
    if (idSesion != null) body['id_sesion'] = idSesion;

    final response = await http
        .post(
          Uri.parse('$_base${ApiConstants.chatEndpoint}'),
          headers: {
            'Content-Type':  'application/json',
            'Accept':        'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 35));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return {
        'id_sesion': data['id_sesion']?.toString() ?? '',
        'respuesta': data['respuesta']?.toString() ?? '',
      };
    }

    throw Exception(data['message'] ?? 'Error al enviar el mensaje.');
  }

  // ── Historial de una sesión ─────────────────────────────────────────────────
  Future<List<ChatMessage>> obtenerHistorial(String idSesion) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$_base${ApiConstants.chatHistoryEndpoint}?id_sesion=$idSesion'),
      headers: {
        'Accept':        'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data     = jsonDecode(response.body) as Map<String, dynamic>;
      final mensajes = data['mensajes'] as List<dynamic>? ?? [];
      return mensajes
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
