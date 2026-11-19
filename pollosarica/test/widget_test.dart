
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pollosarica/features/bienvenida/bienvenida_screen.dart';

void main() {
  testWidgets(
    'La pantalla de bienvenida muestra su contenido correctamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestApp(),
      );

      expect(find.text('¡Bienvenido!'), findsOneWidget);
      expect(find.text('Ver menú'), findsOneWidget);

      expect(
        find.text(
          'Descubre nuestros productos y disfruta '
          'de todo lo que tenemos para ofrecerte.',
        ),
        findsOneWidget,
      );

      expect(
        find.text('Con el sazón de la casa'),
        findsNothing,
      );
    },
  );
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BienvenidaScreen(),
    );
  }
}
