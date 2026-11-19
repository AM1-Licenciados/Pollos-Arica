
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pollosarica_admin/features/autenticacion/login_screen.dart';

void main() {
  testWidgets('La pantalla de inicio de sesión se construye',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Pollos Arica Admin'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
