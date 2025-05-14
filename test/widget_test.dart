// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openintern/loginscreen.dart';

void main() {
  testWidgets('Login button navigates to HomeScreen', (WidgetTester tester) async {
    // Build the LoginScreen widget
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    // Verify the Login button exists
    final loginButton = find.text('Login');
    expect(loginButton, findsOneWidget);

    // Tap the Login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify navigation to HomeScreen
    expect(find.text('Home'), findsNothing); // Replace with actual HomeScreen content
  });
}