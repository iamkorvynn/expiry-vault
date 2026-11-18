import 'package:expiryvault/models/document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpiryDocument', () {
    test('toMap/fromMap round-trip preserves every field', () {
      final doc = ExpiryDocument(
        id: 3,
        type: DocumentType.vehicleInsurance,
        title: 'Honda City Insurance',
        documentNumber: 'POL123456',
        issuingAuthority: 'HDFC ERGO',
        expiryDate: DateTime(2027, 3, 15),
        photoPath: '/docs/photos/abc.jpg',
        createdAt: DateTime(2026, 11, 18, 10, 30),
        updatedAt: DateTime(2026, 11, 18, 10, 30),
      );
      final restored = ExpiryDocument.fromMap(doc.toMap());
      expect(restored.id, 3);
      expect(restored.type, DocumentType.vehicleInsurance);
      expect(restored.title, 'Honda City Insurance');
      expect(restored.documentNumber, 'POL123456');
      expect(restored.issuingAuthority, 'HDFC ERGO');
      expect(restored.expiryDate, DateTime(2027, 3, 15));
      expect(restored.photoPath, '/docs/photos/abc.jpg');
    });

    test('optional fields survive a round-trip as null', () {
      final doc = ExpiryDocument(
        type: DocumentType.puc,
        title: 'PUC',
        documentNumber: 'PUC001',
        expiryDate: DateTime(2027, 1, 1),
      );
      final restored = ExpiryDocument.fromMap(doc.toMap());
      expect(restored.issuingAuthority, isNull);
      expect(restored.photoPath, isNull);
    });

    test('unknown type name falls back to other', () {
      final doc = ExpiryDocument.fromMap(<String, Object?>{
        'id': 1,
        'type': 'not_a_real_type',
        'title': 'X',
        'document_number': 'N1',
        'issuing_authority': null,
        'expiry_date': DateTime(2027, 1, 1).toIso8601String(),
        'photo_path': null,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(doc.type, DocumentType.other);
    });

    test('copyWith updates only the given fields', () {
      final doc = ExpiryDocument(
        id: 1,
        type: DocumentType.passport,
        title: 'Passport',
        documentNumber: 'P123',
        expiryDate: DateTime(2027, 1, 1),
      );
      final renewed = doc.copyWith(expiryDate: DateTime(2032, 1, 1));
      expect(renewed.expiryDate, DateTime(2032, 1, 1));
      expect(renewed.title, 'Passport');
      expect(renewed.id, 1);
    });
  });

  group('DocumentType', () {
    test('every type has a non-empty label', () {
      for (final t in DocumentType.values) {
        expect(t.label, isNotEmpty);
        expect(t.shortLabel, isNotEmpty);
      }
    });

    test('fromName round-trips all types', () {
      for (final t in DocumentType.values) {
        expect(DocumentTypeX.fromName(t.name), t);
      }
    });
  });

  group('RenewalRecord', () {
    test('toMap/fromMap round-trip', () {
      final record = RenewalRecord(
        id: 5,
        documentId: 2,
        oldExpiryDate: DateTime(2026, 11, 18),
        newExpiryDate: DateTime(2027, 11, 18),
        renewedAt: DateTime(2026, 11, 18, 9),
      );
      final restored = RenewalRecord.fromMap(record.toMap());
      expect(restored.id, 5);
      expect(restored.documentId, 2);
      expect(restored.oldExpiryDate, DateTime(2026, 11, 18));
      expect(restored.newExpiryDate, DateTime(2027, 11, 18));
    });
  });
}
