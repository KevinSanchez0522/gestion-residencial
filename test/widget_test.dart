import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:proyecto_delegado/screens/auth/login_screen.dart';
import 'package:proyecto_delegado/viewmodels/auth_viewmodel.dart';

void main() {
  testWidgets('La pantalla de login se renderiza correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
