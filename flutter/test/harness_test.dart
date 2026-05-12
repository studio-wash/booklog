import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('harness smoke', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('ok')));
    await tester.pump();
    expect(find.text('ok'), findsOneWidget);
  });
}
