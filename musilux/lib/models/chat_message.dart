/// Representa un mensaje individual dentro de una sesión de chat con la IA.
class ChatMessage {
  final String id;

  /// 'usuario' | 'asistente'
  final String rol;

  final String contenido;
  final DateTime creadoEn;

  ChatMessage({
    required this.id,
    required this.rol,
    required this.contenido,
    required this.creadoEn,
  });

  bool get esUsuario   => rol == 'usuario';
  bool get esAsistente => rol == 'asistente';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id:        json['id']?.toString() ?? '',
        rol:       json['rol']?.toString() ?? 'usuario',
        contenido: json['contenido']?.toString() ?? '',
        creadoEn:  json['creado_en'] != null
            ? DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Crea un mensaje local (optimista) antes de que el backend confirme.
  factory ChatMessage.local({
    required String rol,
    required String contenido,
  }) =>
      ChatMessage(
        id:        DateTime.now().microsecondsSinceEpoch.toString(),
        rol:       rol,
        contenido: contenido,
        creadoEn:  DateTime.now(),
      );
}
