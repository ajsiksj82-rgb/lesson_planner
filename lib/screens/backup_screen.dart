import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:lesson_planner/services/backup_service.dart';
import 'package:lesson_planner/widgets/common.dart';


class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _svc = BackupService();
  List<File>? _files;
  String? _dir;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.backupDir();
      final f = await _svc.list();
      if (mounted) {
        setState(() {
          _dir = d.path;
          _files = f;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _files = []);
        toast(context, 'تعذر الوصول إلى مجلد النسخ: $e');
      }
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final f = await _svc.export();
      if (mounted) toast(context, 'تم الحفظ: ${p.basename(f.path)}');
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'فشل الحفظ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(File f) async {
    final ok = await confirmDialog(context, 'استرجاع النسخة', 'سيتم استبدال بياناتك الحالية (التعديلات والإعدادات) بمحتوى هذه النسخة. المتابعة؟', ok: 'استرجاع');
    if (!ok) return;
    setState(() => _busy = true);
    final r = await _svc.restoreFrom(f);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, r.ok ? 'تم الاسترجاع بنجاح' : r.error!);
  }

  Future<void> _delete(File f) async {
    final ok = await confirmDialog(context, 'حذف النسخة', 'حذف الملف ${p.basename(f.path)} نهائياً؟', ok: 'حذف');
    if (!ok) return;
    try {
      await f.delete();
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي بالملفات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.save_alt),
            label: const Text('حفظ نسخة احتياطية الآن'),
          ),
          const SizedBox(height: 8),
          if (_dir != null) Text('المجلد: $_dir', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
          const SizedBox(height: 12),
          if (files == null)
            const Center(child: CircularProgressIndicator())
          else if (files.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد نسخ محفوظة بعد')))
          else
            for (final f in files)
              Card(
                child: ListTile(
                  title: Text(p.basename(f.path), style: const TextStyle(fontSize: 13)),
                  leading: const Icon(Icons.description_outlined),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: _busy ? null : () => _restore(f), icon: const Icon(Icons.restore), tooltip: 'استرجاع'),
                    IconButton(onPressed: _busy ? null : () => _delete(f), icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'حذف'),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}
