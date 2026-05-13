import 'dart:html' as html;
import 'package:flutter/material.dart';

void attachMessageListener(GlobalKey<NavigatorState> navigatorKey) {
  try {
    html.window.onMessage.listen((event) {
      final data = event.data;
      try {
        if (data is Map && data['type'] == 'checkout_completed') {
          // Navegar a mis-compras
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/mis-compras',
            (r) => false,
          );
        }
      } catch (_) {}
    });
  } catch (_) {}
}
