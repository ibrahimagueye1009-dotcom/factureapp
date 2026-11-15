import 'package:flutter_test/flutter_test.dart';
import 'package:facturation_pro/main.dart';

void main() {
  testWidgets(
    'L’application de facturation démarre correctement',
    (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Factures'), findsOneWidget);
    },
  );
}
