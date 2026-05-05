import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medication_reminder_app/main.dart';

void main() {
  testWidgets('App builds with MedReminder root', (WidgetTester tester) async {
    await tester.pumpWidget(const MedReminderApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
