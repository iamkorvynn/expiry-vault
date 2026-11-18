import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/document.dart';

/// Local SQLite storage for documents and their renewal history.
/// All data stays on the device; nothing is uploaded anywhere.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null) return db;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'expiry_vault.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            document_number TEXT NOT NULL,
            issuing_authority TEXT,
            expiry_date TEXT NOT NULL,
            photo_path TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE renewals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER NOT NULL,
            old_expiry_date TEXT NOT NULL,
            new_expiry_date TEXT NOT NULL,
            renewed_at TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents(id)
              ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_documents_expiry ON documents(expiry_date)',
        );
      },
    );
  }

  /// All documents, soonest expiry first.
  Future<List<ExpiryDocument>> getAllDocuments() async {
    final db = await database;
    final rows = await db.query(
      'documents',
      orderBy: 'expiry_date ASC',
    );
    return rows.map(ExpiryDocument.fromMap).toList(growable: false);
  }

  Future<ExpiryDocument?> getDocument(int id) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExpiryDocument.fromMap(rows.first);
  }

  Future<int> insertDocument(ExpiryDocument doc) async {
    final db = await database;
    final map = doc.toMap()..remove('id');
    return db.insert('documents', map);
  }

  Future<int> updateDocument(ExpiryDocument doc) async {
    final db = await database;
    return db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[doc.id],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await database;
    await db.delete(
      'renewals',
      where: 'document_id = ?',
      whereArgs: <Object?>[id],
    );
    return db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Mark a document renewed: record the old expiry in history and
  /// update the document to the new expiry date.
  Future<void> renewDocument(ExpiryDocument doc, DateTime newExpiry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'renewals',
        RenewalRecord(
          documentId: doc.id!,
          oldExpiryDate: doc.expiryDate,
          newExpiryDate: newExpiry,
        ).toMap(),
      );
      await txn.update(
        'documents',
        doc.copyWith(expiryDate: newExpiry).toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[doc.id],
      );
    });
  }

  Future<List<RenewalRecord>> getRenewals(int documentId) async {
    final db = await database;
    final rows = await db.query(
      'renewals',
      where: 'document_id = ?',
      whereArgs: <Object?>[documentId],
      orderBy: 'renewed_at DESC',
    );
    return rows.map(RenewalRecord.fromMap).toList(growable: false);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
