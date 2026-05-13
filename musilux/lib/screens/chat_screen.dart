import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal del ChatBot
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Hace scroll al último mensaje tras el frame actual
  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _inputController.text.trim();
    if (texto.isEmpty) return;

    _inputController.clear();
    await context.read<ChatProvider>().enviarMensaje(texto);
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildListaMensajes()),
          _buildCampoEntrada(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.headerBg,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Asistente Musilux',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                'Siempre activo',
                style: TextStyle(fontSize: 11, color: Color(0xFF4ADE80)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_rounded),
          tooltip: 'Nueva conversación',
          onPressed: () async => context.read<ChatProvider>().nuevaConversacion(),
        ),
      ],
    );
  }

  // ── Lista de mensajes ───────────────────────────────────────────────────────
  Widget _buildListaMensajes() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        // Mostrar error si existe
        if (chat.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(chat.error!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            chat.clearError();
          });
        }

        if (chat.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chat.mensajes.isEmpty) {
          return _buildPantallaVacia();
        }

        _scrollAlFinal();

        final total = chat.mensajes.length + (chat.enviando ? 1 : 0);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: total,
          itemBuilder: (context, i) {
            if (chat.enviando && i == chat.mensajes.length) {
              return const _TypingIndicator();
            }
            return _ChatBubble(mensaje: chat.mensajes[i]);
          },
        );
      },
    );
  }

  // ── Pantalla vacía / bienvenida ─────────────────────────────────────────────
  Widget _buildPantallaVacia() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Hola! Soy el asistente de Musilux',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pregúntame sobre productos musicales,\nel estado de tus pedidos o soporte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _SugerenciaChip('¿Qué guitarras tienen disponibles?'),
                _SugerenciaChip('¿Cuál es el estado de mi pedido?'),
                _SugerenciaChip('Quiero información sobre teclados'),
                _SugerenciaChip('Tengo un problema con mi compra'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Campo de entrada ────────────────────────────────────────────────────────
  Widget _buildCampoEntrada() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── TextField ────────────────────────────────────────────────
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  enabled: !chat.enviando,
                  style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _enviar(),
                ),
              ),
              const SizedBox(width: 8),
              // ── Botón enviar ─────────────────────────────────────────────
              Material(
                color: chat.enviando ? AppColors.textDisabled : AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: chat.enviando ? null : _enviar,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: chat.enviando
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: burbuja de mensaje
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage mensaje;
  const _ChatBubble({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;
    final maxWidth  = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esUsuario) ...[
            _BotAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: esUsuario ? AppColors.primaryPurple : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(esUsuario ? 18 : 4),
                    bottomRight: Radius.circular(esUsuario ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  mensaje.contenido,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: esUsuario ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (esUsuario) ...[
            const SizedBox(width: 8),
            _UserAvatar(),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatares
// ─────────────────────────────────────────────────────────────────────────────

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CircleAvatar(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B2E), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.smart_toy_rounded,
      );
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CircleAvatar(
        gradient: AppColors.heroGradient,
        icon: Icons.person_rounded,
      );
}

class _CircleAvatar extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  const _CircleAvatar({required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: indicador de "escribiendo..." animado
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context2, child2) {
                    final t       = (_ctrl.value - i * 0.25).clamp(0.0, 1.0);
                    final opacity = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: chip de sugerencia rápida
// ─────────────────────────────────────────────────────────────────────────────

class _SugerenciaChip extends StatelessWidget {
  final String texto;
  const _SugerenciaChip(this.texto);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        texto,
        style: const TextStyle(fontSize: 12.5, color: AppColors.primaryPurple),
      ),
      backgroundColor: AppColors.primaryLight,
      side: const BorderSide(color: AppColors.primaryPurple, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => context.read<ChatProvider>().enviarMensaje(texto),
    );
  }
}
