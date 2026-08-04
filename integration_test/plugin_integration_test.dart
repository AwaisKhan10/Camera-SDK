// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hr_beauty_cam_sdk/hr_beauty_cam_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize test', (WidgetTester tester) async {
    final HRBeautyCamSdk sdk = HRBeautyCamSdk();
    final bool ok = await sdk.initialize();
    expect(ok, isTrue);
    expect(sdk.isInitialized, isTrue);
    await sdk.dispose();
  });
}
