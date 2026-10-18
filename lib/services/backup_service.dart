import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:lesson_planner/app/app_state.dart';


class BackupResult {
  const BackupResult({this.error});
  final String? error;
  bool get ok => error == null;
}

/// نسخ احتياطي بملفات JSON داخل مجلد التطبيق (backups) على الجهاز.
class BackupService {
  BackupService({Future<Directory> Function()? dirProvider}) : _dirProvider = dirProvider;
  final Future<Directory> Function()? _dirProvider;

  Future<Directory> backupDir() async {
    if (_dirProvider != null) return _dirProvider();
    Directory? base;
    try {
      base = await getExternalStorageDirectory();
    } catch (_) {}
    base ??= await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'backups'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<File> export() async {
    final dir = await backupDir();
    final n = DateTime.now();
    final name = 'planner_backup_${n.year}-${_two(n.month)}-${_two(n.day)}_${_two(n.hour)}${_two(n.minute)}${_two(n.second)}.json';
    final f = File(p.join(dir.path, name));
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(Store.I.toJson()));
    return f;
  }

  Future<List<File>> list() async {
    final dir = await backupDir();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<BackupResult> restoreFrom(File file) async {
    dynamic data;
    try {
      data = jsonDecode(await file.readAsString());
    } catch (_) {
      return const BackupResult(error: 'تعذرت قراءة الملف أو أنه ليس JSON صالحاً');
    }
    final err = Store.validateState(data);
    if (err != null) return BackupResult(error: err);
    Store.I.fromJson(Map<String, dynamic>.from(data as Map));
    Store.I.touch();
    await Store.I.save();
    return const BackupResult();
  }
}
