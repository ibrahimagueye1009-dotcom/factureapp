import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:facturation_pro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facturation_pro/companies.dart';
import 'package:facturation_pro/services/account.dart';
import 'package:facturation_pro/services/profile.dart';

void main() {
  testWidgets(
    'L’application de facturation démarre correctement',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await AccountStore.create('Test', 'test@example.com', 'password');
      await ProfileStore.save(
          Company.custom(id: 'test-company', name: 'Entreprise Test'));
      await tester.pumpWidget(const FacturationApp());
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Factures'), findsOneWidget);
    },
  );

  testWidgets('Un compte neuf ouvre la configuration de son entreprise',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AccountStore.create('Nouveau', 'nouveau@example.com', 'password');

    await tester.pumpWidget(const FacturationApp());
    await tester.pumpAndSettle();

    expect(find.text('Configurer mon entreprise'), findsOneWidget);
    final nameField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.labelText == 'Nom de l’entreprise');
    expect(nameField, findsOneWidget);
  });
}
