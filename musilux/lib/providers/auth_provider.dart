import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Proveedor reactivo de sesión. Envuelve [AuthService] y expone el estado
/// del usuario autenticado a toda la app mediante ChangeNotifier.
///
/// Las pantallas existentes que usan [AuthService] directamente siguen
/// funcionando sin cambios — este provider es la capa reactiva adicional.
class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthUser? _usuario;
  bool _cargando = false;

  AuthUser? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get estaAutenticado => _usuario != null;

  // ── Getters de conveniencia ──────────────────────────────────────────────
  String get rolActual => _usuario?.rol ?? 'visitante';
  bool get esSuperAdmin    => _usuario?.esSuperAdmin ?? false;
  bool get esCliente       => rolActual == 'cliente';
  bool get esAdminPedidos  => rolActual == 'admin_pedidos';
  bool get esAdminUsuarios => rolActual == 'admin_usuarios';
  bool get esAdminInventario => rolActual == 'admin_inventario';
  bool get esAdminVentas   => rolActual == 'admin_ventas';
  bool get esAdminSoporte  => rolActual == 'admin_soporte';

  bool tienePermiso(String permiso) =>
      _usuario?.tienePermiso(permiso) ?? false;

  bool esAlgunRol(List<String> roles) => roles.contains(rolActual);

  // ── Inicialización ───────────────────────────────────────────────────────
  /// Restaura la sesión guardada al iniciar la app.
  Future<void> init() async {
    await _service.restoreSession(); // restaura el token en ProductService.authToken
    _usuario = await _service.getUser();
    notifyListeners();
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _cargando = true;
    notifyListeners();

    final result = await _service.login(email: email, password: password);

    if (result.success) {
      _usuario = result.user;
    }

    _cargando = false;
    notifyListeners();

    return result;
  }

  // ── Registro ─────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String nombres,
    required String apellidos,
    required String correo,
    required String contrasena,
  }) async {
    _cargando = true;
    notifyListeners();

    final result = await _service.register(
      nombres: nombres,
      apellidos: apellidos,
      correo: correo,
      contrasena: contrasena,
    );

    if (result.success) {
      _usuario = result.user;
    }

    _cargando = false;
    notifyListeners();

    return result;
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _usuario = null;
    notifyListeners();
  }
}
