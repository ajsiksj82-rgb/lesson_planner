import 'package:sqflite/sqflite.dart';

/// طبقة التخزين المحلي: جدول واحد (مفتاح/قيمة) يحمل حالة التطبيق كاملة بصيغة JSON.
class AppDatabase {
  AppDatabase._(this._db);
  final Database _db;

  static const String _stateKey = 'state';

  static Future<AppDatabase> open({String? path}) async {
    final dir = path ?? '${await getDatabasesPath()}/lesson_planner.db';
    final db = await openDatabase(
      dir,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT)');
      },
    );
    return AppDatabase._(db);
  }

  Future<String?> loadState() async {
    final rows = await _db.query('kv', where: 'k = ?', whereArgs: [_stateKey]);
    if (rows.isEmpty) return null;
    return rows.first['v'] as String?;
  }

  Future<void> saveState(String json) async {
    await _db.insert('kv', {'k': _stateKey, 'v': json}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() => _db.close();
}
