import 'package:flutter_test/flutter_test.dart';

import 'package:hr_beauty_cam_sdk_example/main.dart';

void main() {
  testWidgets('Verify beauty studio UI loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HrBeautyDemoApp());

    expect(find.text('Shape'), findsOneWidget);
    expect(find.text('AR Effect'), findsOneWidget);
    expect(find.text('Short Effect'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('HR Beauty'), findsOneWidget);
  });
}
