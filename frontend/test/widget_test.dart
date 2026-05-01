import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plastic_watch/core/providers/auth_provider.dart';
import 'package:plastic_watch/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('PlasticWatch'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
  });
}
