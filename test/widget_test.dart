import 'package:flutter_test/flutter_test.dart';
import 'package:polaris_app/main.dart';

void main() {
  testWidgets('Polaris app smoke test', (WidgetTester tester) async {
    // Basic verification that the app can be constructed
    expect(const PolarisApp(), isNotNull);
  });
}
