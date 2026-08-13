import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rozumnyi_koshyk/main.dart';

void main() {
  testWidgets('App boots and shows menu title', (WidgetTester tester) async {
    await tester.pumpWidget(const RozumnyiKoshykApp());
    await tester.pumpAndSettle();
    expect(find.text('Меню на тиждень'), findsOneWidget);
  });
}
