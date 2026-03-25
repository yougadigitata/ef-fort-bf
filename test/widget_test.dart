import 'package:flutter_test/flutter_test.dart';
import 'package:ef_fort_bf/main.dart';

void main() {
  testWidgets('App should start', (WidgetTester tester) async {
    await tester.pumpWidget(const EfFortApp());
    expect(find.byType(EfFortApp), findsOneWidget);
  });
}
