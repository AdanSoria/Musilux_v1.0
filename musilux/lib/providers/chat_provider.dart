import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Gestiona el estado de la conversación activa con el chatbot de IA.
/// Persiste el id_sesion en SharedPreferences para sobrevivir reinicios de app.
class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  static const String _kSesionKey = 'chat_id_sesion';

  List<ChatMessage> _mensajes = [];
  bool   _enviando  = false;
  bool   _cargando  = false;
  String? _idSesion;
  String? _error;

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<ChatMessage> get mensajes  => List.unmodifiable(_mensajes);
  bool              get enviando  => _enviando;
  bool              get cargando  => _cargando;
  String?           get idSesion  => _idSesion;
  String?           get error     => _error;

  // ── Inicialización — restaura la última sesión desde BD ──────────────────────
  /// Llamar en main.dart después de authProvider.init().
  /// Solo carga historial si el usuario ya está autenticado.
  Future<void> init() async {
    final prefs   = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_kSesionKey);
    if (guardado == null || guardado.isEmpty) return;

    _cargando = true;
    notifyListeners();

    try {
      final mensajes = await _service.obtenerHistorial(guardado);
      if (mensajes.isNotEmpty) {
        _idSesion = guardado;
        _mensajes = mensajes;
      } else {
        // La sesión ya no existe en el backend — limpiar referencia
        await prefs.remove(_kSesionKey);
      }
    } catch (_) {
      // Si falla (sin red, sesión expirada) no bloqueamos la app
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ── Enviar un mensaje ────────────────────────────────────────────────────────
  Future<void> enviarMensaje(String texto) async {
    if (texto.trim().isEmpty || _enviando) return;

    // Actualización UI optimista
    final msgUsuario = ChatMessage.local(rol: 'usuario', contenido: texto.trim());
    _mensajes.add(msgUsuario);
    _enviando = true;
    _error    = null;
    notifyListeners();

    try {
      final result = await _service.enviarMensaje(
        mensaje:  texto.trim(),
        idSesion: _idSesion,
      );

      _idSesion = result['id_sesion'];

      // Persistir el id_sesion para la próxima apertura de la app
      if (_idSesion != null && _idSesion!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kSesionKey, _idSesion!);
      }

      _mensajes.add(
        ChatMessage.local(rol: 'asistente', contenido: result['respuesta'] ?? ''),
      );
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Revertir el mensaje optimista del usuario
      if (_mensajes.isNotEmpty) _mensajes.removeLast();
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  // ── Cargar historial de una sesión existente ─────────────────────────────────
  Future<void> cargarHistorial(String idSesion) async {
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      _idSesion = idSesion;
      _mensajes = await _service.obtenerHistorial(idSesion);
    } on Exception catch (_) {
      _mensajes = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ── Iniciar una nueva conversación ───────────────────────────────────────────
  Future<void> nuevaConversacion() async {
    _mensajes = [];
    _idSesion = null;
    _error    = null;
    _enviando = false;

    // Borrar sesión guardada para que la próxima apertura empiece en blanco
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSesionKey);

    notifyListeners();
  }

  // ── Limpiar error tras mostrarlo ────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
