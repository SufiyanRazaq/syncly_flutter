import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncly_flutter/syncly_flutter.dart';

class LocalStorage {
  static Database? _database;

  Future<void> init() async {
    if (_database != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'syncly_flutter.db');
    print('Database path: $path');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createDatabase(db, version);
        print('Database created successfully!');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDatabase(db, oldVersion, newVersion);
        print('Database upgraded successfully from $oldVersion to $newVersion');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE sync_data (
      id TEXT PRIMARY KEY,
      key TEXT,
      data TEXT,
      previousData TEXT,
      createdAt TEXT,
      updatedAt TEXT,
      status TEXT
    )
  ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sync_data ADD COLUMN previousData TEXT');
    }
  }

  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final newData = SyncData(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      key: key,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: SyncStatus.unsynced,
    );

    print('Saving data: ${newData.toJson()}');

    await _database!.insert(
      'sync_data',
      newData.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Data saved successfully: ${newData.id}');
  }

  Future<List<SyncData>> getAllData() async {
    final List<Map<String, dynamic>> maps = await _database!.query('sync_data');

    print('Fetched all data: ${maps.length} items');

    return List.generate(maps.length, (i) {
      final data = SyncData.fromJson(maps[i]);
      print('Retrieved task: ${data.id} - ${data.data}');
      return data;
    });
  }

  Future<List<SyncData>> getUnsyncedData() async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'sync_data',
      where: 'status = ?',
      whereArgs: [SyncStatus.unsynced.toString().split('.').last],
    );

    print('Fetched unsynced data: ${maps.length} items');

    return List.generate(maps.length, (i) {
      final data = SyncData.fromJson(maps[i]);
      print('Retrieved unsynced task: ${data.id} - ${data.data}');
      return data;
    });
  }

  Future<List<SyncData>> getSyncedData() async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'sync_data',
      where: 'status = ?',
      whereArgs: [SyncStatus.synced.toString().split('.').last],
    );

    print('Fetched synced data: ${maps.length} items');

    return List.generate(maps.length, (i) {
      final data = SyncData.fromJson(maps[i]);
      print('Retrieved synced task: ${data.id} - ${data.data}');
      return data;
    });
  }

  Future<void> clearSyncedTasks() async {
    final count = await _database!.delete(
      'sync_data',
      where: 'status = ?',
      whereArgs: [SyncStatus.synced.toString().split('.').last],
    );

    print('Cleared $count synced tasks from the database.');
  }

  Future<void> markAsSynced(SyncData data) async {
    final updatedData = data.copyWith(
      status: SyncStatus.synced,
      updatedAt: DateTime.now(),
    );

    await _database!.update(
      'sync_data',
      updatedData.toJson(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<void> deleteData(String id) async {
    await _database!.delete(
      'sync_data',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    await _database?.close();
  }
}
