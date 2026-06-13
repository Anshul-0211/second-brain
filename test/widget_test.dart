import 'package:flutter_test/flutter_test.dart';
import 'package:scnd_brain/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SecondBrainApp());
    expect(find.text('Dump'), findsOneWidget);
  });
}
