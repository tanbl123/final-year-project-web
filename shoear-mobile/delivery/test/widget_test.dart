// Smoke test for the courier login screen.
//
// The full app (CourierApp) needs runtime dependencies (API client, auth
// provider, FCM), so instead of building it we render the login screen on its
// own — it only reads providers on submit, so it builds fine standalone — and
// check the key UI is present.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows the courier sign-in UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('ShoeAR Express'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('New here? Apply to be a courier'), findsOneWidget);
  });
}
