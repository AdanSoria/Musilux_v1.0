import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musilux/screens/login_screen.dart';

void main() {
  testWidgets('smoke test — LoginScreen renderiza sin excepciones',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
  });
}
