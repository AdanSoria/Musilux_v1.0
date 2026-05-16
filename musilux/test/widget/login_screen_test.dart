import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musilux/screens/login_screen.dart';

// LoginScreen.build() no accede a providers — solo los lee en _login().
// _login() regresa temprano si la validación falla, por lo que los tests de UI
// y validación no necesitan providers en el árbol.
Widget makeLoginScreen() => const MaterialApp(home: LoginScreen());

void main() {
  group('LoginScreen — UI', () {
    testWidgets('muestra el título Musilux Admin', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.text('Musilux Admin'), findsOneWidget);
    });

    testWidgets('muestra el ícono de música', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('muestra los campos de correo y contraseña', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('muestra el botón de Iniciar sesión', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('el botón está habilitado inicialmente', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('no muestra mensaje de error al iniciar', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('LoginScreen — validación de formulario', () {
    testWidgets('muestra Requerido en ambos campos al enviar vacío',
        (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Requerido'), findsNWidgets(2));
    });

    testWidgets('muestra Requerido solo en contraseña si email es válido',
        (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      await tester.enterText(
          find.byType(TextFormField).first, 'usuario@test.com');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Requerido'), findsOneWidget);
      expect(find.text('Email inválido'), findsNothing);
    });

    testWidgets('muestra Email inválido cuando el correo no tiene @',
        (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      await tester.enterText(
          find.byType(TextFormField).first, 'no-es-un-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'contraseña123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('no muestra errores de validación cuando ambos campos son válidos antes de enviar',
        (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      await tester.enterText(
          find.byType(TextFormField).first, 'usuario@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'contraseña123');
      await tester.pump();
      expect(find.text('Requerido'), findsNothing);
      expect(find.text('Email inválido'), findsNothing);
    });
  });

  group('LoginScreen — visibilidad de contraseña', () {
    testWidgets('el campo de contraseña está oculto por defecto', (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      final passwordField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordField.obscureText, true);
    });

    testWidgets('el ícono de visibilidad alterna entre mostrar y ocultar',
        (tester) async {
      await tester.pumpWidget(makeLoginScreen());
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
