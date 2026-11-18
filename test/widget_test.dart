import 'package:expiryvault/models/document.dart';
import 'package:expiryvault/screens/add_edit_screen.dart';
import 'package:expiryvault/screens/onboarding_screen.dart';
import 'package:expiryvault/utils/expiry_logic.dart';
import 'package:expiryvault/widgets/document_card.dart';
import 'package:expiryvault/widgets/status_badge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('Onboarding shows all three explainer pages and Get started',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('Every document in one vault'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    // Swipe to the last page.
    await tester.drag(
      find.byType(PageView),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(PageView),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Add document form shows all required fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const AddEditScreen()));
    expect(find.text('Add document'), findsOneWidget);
    expect(find.text('Document type'), findsOneWidget);
    expect(find.text('Name / label'), findsOneWidget);
    expect(find.text('Document number'), findsOneWidget);
    expect(find.text('Issuing authority (optional)'), findsOneWidget);
    expect(find.text('Expiry date'), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
    expect(find.text('Save document'), findsOneWidget);
    // Validation: saving with empty fields shows errors, not a crash.
    await tester.tap(find.text('Save document'));
    await tester.pump();
    expect(find.text('Please pick an expiry date.'), findsOneWidget);
  });

  testWidgets('DocumentCard shows title, type, status and days left',
      (WidgetTester tester) async {
    final doc = ExpiryDocument(
      id: 1,
      type: DocumentType.vehicleInsurance,
      title: 'Honda City Insurance',
      documentNumber: 'POL123456',
      expiryDate: DateTime.now().add(const Duration(days: 10)),
    );
    await tester.pumpWidget(
      _wrap(Scaffold(body: DocumentCard(document: doc))),
    );
    expect(find.text('Honda City Insurance'), findsOneWidget);
    expect(find.textContaining('Vehicle Insurance'), findsOneWidget);
    expect(find.text('Expiring Soon'), findsOneWidget);
    expect(find.text('10 days left'), findsOneWidget);
  });

  testWidgets('StatusBadge renders each status label',
      (WidgetTester tester) async {
    for (final status in ExpiryStatus.values) {
      await tester.pumpWidget(
        _wrap(Scaffold(body: StatusBadge(status: status))),
      );
      expect(find.text(statusLabel(status)), findsOneWidget);
    }
  });

  testWidgets('Edit form is pre-filled with the existing document',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final doc = ExpiryDocument(
      id: 2,
      type: DocumentType.passport,
      title: 'My Passport',
      documentNumber: 'A1234567',
      issuingAuthority: 'Govt of India',
      expiryDate: DateTime(2030, 5, 20),
    );
    await tester.pumpWidget(_wrap(AddEditScreen(document: doc)));
    expect(find.text('Edit document'), findsOneWidget);
    expect(find.text('My Passport'), findsOneWidget);
    expect(find.text('A1234567'), findsOneWidget);
    expect(find.text('Govt of India'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
