import 'package:flutter/foundation.dart';

class ApiConstants {
  // URL de producción en Railway — reemplazar con la URL real tras el deploy
  static const String _prodUrl = 'https://musiluxv10-production.up.railway.app/api';

  // IP local para desarrollo (flutter run en debug)
  static const String _devIp = '10.11.5.71';
  static const int _devPort = 8080;

  static String get baseUrl {
    // kDebugMode es false en release/profile → apunta a producción
    if (!kDebugMode) return _prodUrl;
    if (kIsWeb) return 'http://localhost:$_devPort/api';
    return 'http://$_devIp:$_devPort/api';
  }

  static const String productsEndpoint = '/products';
  static const String chatEndpoint = '/chat';
  static const String chatHistoryEndpoint = '/chat/history';
}
