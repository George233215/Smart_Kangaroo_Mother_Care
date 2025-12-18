// lib/services/local_db_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';

class LocalDbService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'baby_care_db.db');
    return await openDatabase(
      path,
      version: 2, // Version changed from 1 to 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table for Sleep Data
    await db.execute('''
      CREATE TABLE sleep_data(
        id TEXT PRIMARY KEY,
        startTime INTEGER,
        endTime INTEGER,
        notes TEXT
      )
    ''');

    // Table for Feeding Data (includes 'side')
    await db.execute('''
      CREATE TABLE feeding_data(
        id TEXT PRIMARY KEY,
        timestamp INTEGER,
        type TEXT,
        side TEXT,
        durationMinutes INTEGER,
        amountMl REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE feeding_data ADD COLUMN side TEXT;");
      } catch (e) {
        print('Upgrade to v2: $e'); // Column may already exist
      }
    }
  }

  // === CRUD Operations for Sleep ===

  Future<void> insertSleep(SleepData sleep) async {
    final db = await database;
    await db.insert(
      'sleep_data',
      sleep.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSleep(SleepData sleep) async {
    final db = await database;
    await db.update(
      'sleep_data',
      sleep.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [sleep.id],
    );
  }

  Future<void> deleteSleep(String id) async {
    final db = await database;
    await db.delete('sleep_data', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SleepData>> getSleepEntries({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_data',
      where: 'startTime >= ?',
      whereArgs: [cutoff],
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => SleepData.fromSqliteMap(maps[i]));
  }

  // === CRUD Operations for Feeding ===

  Future<void> insertFeeding(FeedingData feeding) async {
    final db = await database;
    await db.insert(
      'feeding_data',
      feeding.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFeeding(FeedingData feeding) async {
    final db = await database;
    await db.update(
      'feeding_data',
      feeding.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [feeding.id],
    );
  }

  Future<void> deleteFeeding(String id) async {
    final db = await database;
    await db.delete('feeding_data', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FeedingData>> getFeedingEntries({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'feeding_data',
      where: 'timestamp >= ?',
      whereArgs: [cutoff],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => FeedingData.fromSqliteMap(maps[i]));
  }
}
