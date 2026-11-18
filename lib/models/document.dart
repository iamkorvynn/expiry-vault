import 'package:material_ui/material_ui.dart';

import '../utils/expiry_logic.dart';

/// The document types ExpiryVault tracks.
enum DocumentType {
  puc,
  vehicleInsurance,
  drivingLicence,
  rc,
  passport,
  other,
}

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
        DocumentType.puc => 'PUC',
        DocumentType.vehicleInsurance => 'Vehicle Insurance',
        DocumentType.drivingLicence => 'Driving Licence',
        DocumentType.rc => 'RC / Registration',
        DocumentType.passport => 'Passport',
        DocumentType.other => 'Other Document',
      };

  String get shortLabel => switch (this) {
        DocumentType.puc => 'PUC',
        DocumentType.vehicleInsurance => 'Insurance',
        DocumentType.drivingLicence => 'Licence',
        DocumentType.rc => 'RC',
        DocumentType.passport => 'Passport',
        DocumentType.other => 'Other',
      };

  IconData get icon => switch (this) {
        DocumentType.puc => Icons.cloud_done_outlined,
        DocumentType.vehicleInsurance => Icons.directions_car_outlined,
        DocumentType.drivingLicence => Icons.badge_outlined,
        DocumentType.rc => Icons.description_outlined,
        DocumentType.passport => Icons.flight_takeoff_outlined,
        DocumentType.other => Icons.folder_outlined,
      };

  static DocumentType fromName(String name) =>
      DocumentType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => DocumentType.other,
      );
}

/// A single tracked document.
class ExpiryDocument {
  ExpiryDocument({
    this.id,
    required this.type,
    required this.title,
    required this.documentNumber,
    this.issuingAuthority,
    required this.expiryDate,
    this.photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final DocumentType type;
  final String title;
  final String documentNumber;
  final String? issuingAuthority;
  final DateTime expiryDate;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpiryStatus get status => statusFor(expiryDate);

  int get daysLeft => daysRemaining(expiryDate);

  ExpiryDocument copyWith({
    int? id,
    DocumentType? type,
    String? title,
    String? documentNumber,
    String? issuingAuthority,
    DateTime? expiryDate,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpiryDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      expiryDate: expiryDate ?? this.expiryDate,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'title': title,
      'document_number': documentNumber,
      'issuing_authority': issuingAuthority,
      'expiry_date': expiryDate.toIso8601String(),
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpiryDocument.fromMap(Map<String, Object?> map) {
    return ExpiryDocument(
      id: map['id'] as int?,
      type: DocumentTypeX.fromName(map['type'] as String? ?? 'other'),
      title: map['title'] as String? ?? '',
      documentNumber: map['document_number'] as String? ?? '',
      issuingAuthority: map['issuing_authority'] as String?,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// One renewal event: the old expiry replaced by a new one.
class RenewalRecord {
  RenewalRecord({
    this.id,
    required this.documentId,
    required this.oldExpiryDate,
    required this.newExpiryDate,
    DateTime? renewedAt,
  }) : renewedAt = renewedAt ?? DateTime.now();

  final int? id;
  final int documentId;
  final DateTime oldExpiryDate;
  final DateTime newExpiryDate;
  final DateTime renewedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'document_id': documentId,
      'old_expiry_date': oldExpiryDate.toIso8601String(),
      'new_expiry_date': newExpiryDate.toIso8601String(),
      'renewed_at': renewedAt.toIso8601String(),
    };
  }

  factory RenewalRecord.fromMap(Map<String, Object?> map) {
    return RenewalRecord(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      oldExpiryDate: DateTime.parse(map['old_expiry_date'] as String),
      newExpiryDate: DateTime.parse(map['new_expiry_date'] as String),
      renewedAt: DateTime.parse(map['renewed_at'] as String),
    );
  }
}
