// Web implementation
import 'dart:html' as html;

void notifyCheckoutCompleted() {
  try {
    // Escribir en localStorage para disparar evento storage en otras pestañas
    html.window.localStorage['cart_cleared'] = DateTime.now().toIso8601String();
  } catch (_) {}

  try {
    // Enviar mensaje al opener (si existe)
    if (html.window.opener != null) {
      html.window.opener!.postMessage({'type': 'checkout_completed'}, '*');
      // Intentar cerrar la ventana si fue abierta por script
      try {
        html.window.close();
      } catch (_) {}
    }
  } catch (_) {}
}
