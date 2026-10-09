import 'package:flutter_test/flutter_test.dart';
import 'package:blot/main.dart';

void main() {
  testWidgets('home shows Blot branding and room actions', (tester) async {
    await tester.pumpWidget(const BlotApp());
    expect(find.text('blot'), findsOneWidget);
    expect(find.text('Create a room'), findsOneWidget);
    expect(find.text('Room code'), findsOneWidget);
  });
}
