import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recept24_app/main.dart';

void main() {
  testWidgets('Recept24 app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Recept24App());
    expect(find.text('Recept24'), findsOneWidget);
  });
}
