import 'package:flutter_test/flutter_test.dart';
import 'package:recept24_desktop/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Recept24DesktopApp());
  });
}
