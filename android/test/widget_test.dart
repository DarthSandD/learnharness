import 'package:flutter_test/flutter_test.dart';

import 'package:learnharness_android/main.dart';

void main() {
  testWidgets('LearnHarness v1 shows the home composer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnHarnessApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('LearnHarness'), findsWidgets);
    expect(find.text('What do you want to learn?'), findsOneWidget);
    // Teach and Practice appear twice: once as home actions and once
    // as bottom navigation labels.
    expect(find.text('Teach'), findsNWidgets(2));
    expect(find.text('Practice'), findsNWidgets(2));
  });
}
