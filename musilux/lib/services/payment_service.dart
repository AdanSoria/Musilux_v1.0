import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

class PaymentService {
  PaymentService();

  /// Tries to run the PaymentSheet flow. Returns true on success, false on error.
  /// Returns {'success': bool, 'message': String?}
  Future<Map<String, dynamic>> payWithPaymentSheet(double amount) async {
    // flutter_stripe PaymentSheet is not supported on web. Return a friendly message.
    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'Stripe PaymentSheet no es compatible con Flutter Web. Prueba en Android/iOS o implemente Stripe Checkout para web.',
      };
    }
    try {
      // Llamar backend para crear PaymentIntent
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/checkout/create-payment-intent',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );

      if (resp.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error: ${resp.statusCode} ${resp.body}',
        };
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String?;
      final publishableKey = data['publishableKey'] as String?;

      if (clientSecret == null || publishableKey == null) {
        return {
          'success': false,
          'message': 'Invalid payment data from server: ${resp.body}',
        };
      }

      // Inicializar Stripe con la publishable key
      Stripe.publishableKey = publishableKey;

      await Stripe.instance.applySettings();

      final params = SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Musilux',
        // additional config: countryCode, testEnv, etc.
      );

      await Stripe.instance.initPaymentSheet(paymentSheetParameters: params);

      // Presentar PaymentSheet
      await Stripe.instance.presentPaymentSheet();
      return {'success': true};
    } on StripeException catch (e) {
      // Stripe error — log for diagnostics
      final msg = e.error.localizedMessage ?? e.error.message ?? 'Stripe error';
      // ignore: avoid_print
      print('StripeException: $msg');
      return {'success': false, 'message': 'Stripe error: $msg'};
    } catch (e) {
      // Unexpected error
      // Log and return false; caller should show any UI messages using its own context
      // ignore: avoid_print
      print('PaymentService error: $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  /// Para web: crea una sesión de Stripe Checkout en el backend y devuelve la URL
  /// Retorna {'success': bool, 'url': String? , 'message': String? }
  /// Crea una sesión de Checkout pasando un payload con 'items', 'subtotal', etc.
  /// payload debe tener al menos la clave 'items' como lista.
  Future<Map<String, dynamic>> createCheckoutSessionUrl(
    Map<String, dynamic> payload,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/checkout/create-checkout-session',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Añadir el origin actual del navegador para que el backend pueda
      // construir success_url correctamente (incluyendo puerto dinámico).
      final payloadWithFrontend = Map<String, dynamic>.from(payload);
      try {
        // Uri.base.origin funciona en web y contiene scheme://host:port
        payloadWithFrontend['frontend'] = Uri.base.origin;
      } catch (_) {}

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payloadWithFrontend),
      );

      if (resp.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error: ${resp.statusCode} ${resp.body}',
        };
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null) {
        return {
          'success': false,
          'message': 'No checkout url returned from server',
        };
      }
      return {'success': true, 'url': url};
    } catch (e) {
      // ignore: avoid_print
      print('createCheckoutSessionUrl error: $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}
