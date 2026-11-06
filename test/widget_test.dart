import 'package:flutter_test/flutter_test.dart';
import 'package:your_ott/main.dart';

void main() {
  testWidgets('Your OTT home screen renders', (tester) async {
    await tester.pumpWidget(const YourOttApp());
    expect(find.text('YOUR OTT'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
  });
}
