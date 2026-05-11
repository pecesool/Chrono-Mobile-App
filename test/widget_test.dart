import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chrono_app/app.dart';

void main() {
  testWidgets('Chrono app loads', (WidgetTester tester) async {
    await tester.pumpWidget(ChronoApp());
    expect(find.text('Chrono'), findsOneWidget);
  });
}
