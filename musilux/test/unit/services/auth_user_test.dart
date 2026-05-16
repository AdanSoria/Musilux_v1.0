import 'package:flutter_test/flutter_test.dart';
import 'package:musilux/services/auth_service.dart';

void main() {
  group('AuthUser.fromJson', () {
    Map<String, dynamic> validJson() => {
          'id': '1',
          'id_rol': 2,
          'rol': 'cliente',
          'permisos': ['ver_productos', 'comprar'],
          'nombres': 'Juan',
          'apellidos': 'Pérez',
          'correo': 'juan@example.com',
        };

    test('parsea todos los campos', () {
      final user = AuthUser.fromJson(validJson());
      expect(user.id, '1');
      expect(user.idRol, 2);
      expect(user.rol, 'cliente');
      expect(user.permisos, ['ver_productos', 'comprar']);
      expect(user.nombres, 'Juan');
      expect(user.apellidos, 'Pérez');
      expect(user.correo, 'juan@example.com');
    });

    test('usa valores por defecto cuando faltan campos', () {
      final user = AuthUser.fromJson({});
      expect(user.id, '');
      expect(user.nombres, '');
      expect(user.correo, '');
      expect(user.permisos, isEmpty);
      expect(user.idRol, isNull);
      expect(user.rol, isNull);
    });

    test('getters de conveniencia nombre y email funcionan', () {
      final user = AuthUser.fromJson(validJson());
      expect(user.nombre, 'Juan');
      expect(user.email, 'juan@example.com');
    });

    test('permisos como lista vacía no falla', () {
      final json = validJson();
      json['permisos'] = [];
      final user = AuthUser.fromJson(json);
      expect(user.permisos, isEmpty);
    });
  });

  group('AuthUser.esSuperAdmin', () {
    test('es true cuando rol es superadmin', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Admin',
        'correo': 'a@b.com',
        'rol': 'superadmin',
      });
      expect(user.esSuperAdmin, true);
    });

    test('es false para rol cliente', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Juan',
        'correo': 'j@b.com',
        'rol': 'cliente',
      });
      expect(user.esSuperAdmin, false);
    });

    test('es false cuando rol es null', () {
      final user = AuthUser.fromJson({'id': '1', 'nombres': 'Sin rol', 'correo': 'a@b.com'});
      expect(user.esSuperAdmin, false);
    });
  });

  group('AuthUser.tienePermiso', () {
    test('superadmin tiene cualquier permiso', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Admin',
        'correo': 'a@b.com',
        'rol': 'superadmin',
        'permisos': [],
      });
      expect(user.tienePermiso('cualquier_permiso'), true);
      expect(user.tienePermiso('admin_dashboard'), true);
    });

    test('usuario regular verifica contra su lista de permisos', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Juan',
        'correo': 'j@b.com',
        'rol': 'cliente',
        'permisos': ['ver_productos'],
      });
      expect(user.tienePermiso('ver_productos'), true);
      expect(user.tienePermiso('admin_dashboard'), false);
    });

    test('usuario sin permisos no tiene acceso a nada', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Juan',
        'correo': 'j@b.com',
        'rol': 'cliente',
        'permisos': [],
      });
      expect(user.tienePermiso('ver_productos'), false);
    });
  });

  group('AuthUser.esRol', () {
    test('retorna true cuando el rol coincide exactamente', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Juan',
        'correo': 'j@b.com',
        'rol': 'admin_pedidos',
      });
      expect(user.esRol('admin_pedidos'), true);
    });

    test('retorna false cuando el rol no coincide', () {
      final user = AuthUser.fromJson({
        'id': '1',
        'nombres': 'Juan',
        'correo': 'j@b.com',
        'rol': 'cliente',
      });
      expect(user.esRol('superadmin'), false);
    });
  });

  group('AuthUser.toJson round-trip', () {
    test('serializa y deserializa correctamente', () {
      final original = AuthUser.fromJson({
        'id': '5',
        'id_rol': 1,
        'rol': 'admin_pedidos',
        'permisos': ['ver_pedidos', 'actualizar_pedidos'],
        'nombres': 'Ana',
        'apellidos': 'López',
        'correo': 'ana@example.com',
      });
      final decoded = AuthUser.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.rol, original.rol);
      expect(decoded.correo, original.correo);
      expect(decoded.permisos, original.permisos);
      expect(decoded.nombres, original.nombres);
    });
  });

  group('AuthResult', () {
    test('success inicializa correctamente', () {
      final user = AuthUser.fromJson(
          {'id': '1', 'nombres': 'Test', 'correo': 't@t.com'});
      final result = AuthResult.success('token_abc_123', user);
      expect(result.success, true);
      expect(result.token, 'token_abc_123');
      expect(result.user?.id, '1');
      expect(result.error, isNull);
    });

    test('failure inicializa correctamente', () {
      final result = AuthResult.failure('Credenciales incorrectas');
      expect(result.success, false);
      expect(result.error, 'Credenciales incorrectas');
      expect(result.token, isNull);
      expect(result.user, isNull);
    });
  });
}
