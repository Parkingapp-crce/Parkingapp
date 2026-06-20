import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:park_owner/main.dart';

void main() {
  testWidgets('Owner app boots', (WidgetTester tester) async {
    await tester.pumpWidget(ParkEasyOwnerApp(
      themeNotifier: ThemeNotifier(ThemeMode.light),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Owner Login'), findsOneWidget);
  });
}
