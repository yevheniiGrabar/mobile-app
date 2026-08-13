import 'package:flutter_test/flutter_test.dart';

import 'package:rozumnyi_koshyk/main.dart';

void main() {
  testWidgets('App boots and shows home', (WidgetTester tester) async {
    await tester.pumpWidget(const RozumnyiKoshykApp());
    await tester.pumpAndSettle();
    expect(find.text('Mealize'), findsOneWidget);
    expect(find.text('Тижневий бюджет'), findsOneWidget);
  });
}
