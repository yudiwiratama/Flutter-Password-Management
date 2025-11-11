import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_model.dart';
import '../services/security_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('passwords.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE passwords (
        id $idType,
        title $textType,
        username $textType,
        password $textType,
        website $textTypeNullable,
        notes $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');
  }

  // CREATE - Insert a new password
  Future<int> createPassword(PasswordModel password) async {
    final db = await database;
    final encrypted = await _encryptPassword(password);
    return await db.insert('passwords', encrypted);
  }

  // READ - Get all passwords
  Future<List<PasswordModel>> getAllPasswords() async {
    final db = await database;
    const orderBy = 'updated_at DESC';
    final result = await db.query('passwords', orderBy: orderBy);

    final decrypted = <PasswordModel>[];
    for (final map in result) {
      decrypted.add(await _decryptPassword(map));
    }
    return decrypted;
  }

  // READ - Get a single password by id
  Future<PasswordModel?> getPassword(int id) async {
    final db = await database;
    final maps = await db.query(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _decryptPassword(maps.first);
    }
    return null;
  }

  // READ - Search passwords by title or username
  Future<List<PasswordModel>> searchPasswords(String query) async {
    final all = await getAllPasswords();
    final lowerQuery = query.toLowerCase();
    return all.where((password) {
      final titleMatch = password.title.toLowerCase().contains(lowerQuery);
      final usernameMatch =
          password.username.toLowerCase().contains(lowerQuery);
      final websiteMatch =
          (password.website ?? '').toLowerCase().contains(lowerQuery);
      return titleMatch || usernameMatch || websiteMatch;
    }).toList();
  }

  // UPDATE - Update a password
  Future<int> updatePassword(PasswordModel password) async {
    final db = await database;
    final encrypted = await _encryptPassword(password);
    return await db.update(
      'passwords',
      encrypted,
      where: 'id = ?',
      whereArgs: [password.id],
    );
  }

  // DELETE - Delete a password
  Future<int> deletePassword(int id) async {
    final db = await database;
    return await db.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Delete all passwords
  Future<int> deleteAllPasswords() async {
    final db = await database;
    return await db.delete('passwords');
  }

  Future<List<Map<String, dynamic>>> getAllEncryptedRows() async {
    final db = await database;
    return await db.query('passwords', orderBy: 'updated_at DESC');
  }

  Future<void> importPasswords(List<PasswordModel> passwords) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('passwords');
      for (final password in passwords) {
        final map = await _encryptPassword(password);
        map.remove('id');
        await txn.insert('passwords', map);
      }
    });
  }

  Future<void> importEncryptedRows(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('passwords');
      for (final row in rows) {
        await txn.insert(
          'passwords',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get count of passwords
  Future<int> getPasswordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM passwords');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<Map<String, dynamic>> _encryptPassword(
    PasswordModel password,
  ) async {
    final security = SecurityService.instance;
    final map = password.toMap();

    map['title'] = await security.encrypt(map['title'] as String);
    map['username'] = await security.encrypt(map['username'] as String);
    map['password'] = await security.encrypt(map['password'] as String);

    final website = map['website'] as String?;
    map['website'] = website == null || website.isEmpty
        ? null
        : await security.encrypt(website);

    final notes = map['notes'] as String?;
    map['notes'] = notes == null || notes.isEmpty
        ? null
        : await security.encrypt(notes);

    return map;
  }

  Future<PasswordModel> _decryptPassword(
    Map<String, dynamic> map,
  ) async {
    final security = SecurityService.instance;

    final title = await security.decrypt(map['title'] as String);
    final username = await security.decrypt(map['username'] as String);
    final password = await security.decrypt(map['password'] as String);
    final websiteValue = map['website'] as String?;
    final notesValue = map['notes'] as String?;

    final website = websiteValue == null
        ? null
        : await security.decrypt(websiteValue);
    final notes =
        notesValue == null ? null : await security.decrypt(notesValue);

    return PasswordModel(
      id: map['id'] as int?,
      title: title,
      username: username,
      password: password,
      website: website,
      notes: notes,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

