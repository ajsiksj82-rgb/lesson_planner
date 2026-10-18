import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:lesson_planner/data/curriculum_data.dart';
import 'package:lesson_planner/data/timetable.dart';
import 'package:lesson_planner/database/app_database.dart';
import 'package:lesson_planner/models/models.dart';
import 'package:lesson_planner/utils/date_utils.dart';


// ---------- المخزن (حالة التطبيق + SQLite) ----------
class Store extends ChangeNotifier {
  static final Store I = Store._();
  Store._();

  late Map<String, dynamic> cur;
  AppDatabase? _db;
  Timer? _timer;
  bool dbFailed = false;

  String teacher = 'أحمد داود طه شريف';
  String school = 'مدارس الفجر الأهلية';
  String start = '2026-10-18';
  int switchHour = 14;
  bool onboarded = false;
  Map<String, int> offsets = {};
  Set<String> skips = {};
  List<String> holidays = [];
  Map<String, dynamic> edits = {};
  Map<String, Map<String, String>> refl = {};
  Set<String> done = {};

  Future<void> init({AppDatabase? db}) async {
    cur = jsonDecode(kCurriculum) as Map<String, dynamic>;
    try {
      _db = db ?? await AppDatabase.open();
      final s = await _db!.loadState();
      if (s != null) {
        fromJson(jsonDecode(s) as Map<String, dynamic>);
      }
    } catch (e) {
      // في حال تعذر فتح القاعدة يعمل التطبيق دون حفظ دائم
      dbFailed = true;
    }
  }

  /// يتحقق من أن النص نسخة احتياطية صالحة لهذا التطبيق. يرجع رسالة الخطأ أو null.
  static String? validateState(dynamic data) {
    if (data is! Map) return 'تنسيق الملف غير صحيح';
    if (data['app'] != null && data['app'] != 'lesson_planner') return 'هذا الملف ليس نسخة احتياطية لمخطط التحضير';
    if (data['v'] is! int) return 'إصدار النسخة غير معروف';
    if ((data['v'] as int) > 1) return 'النسخة أحدث من إصدار التطبيق الحالي';
    for (final k in ['offsets', 'edits', 'refl']) {
      if (data[k] != null && data[k] is! Map) return 'حقل $k غير صالح';
    }
    for (final k in ['skips', 'holidays', 'done']) {
      if (data[k] != null && data[k] is! List) return 'حقل $k غير صالح';
    }
    return null;
  }

  void fromJson(Map<String, dynamic> j) {
    teacher = '${j['teacher'] ?? teacher}';
    school = '${j['school'] ?? school}';
    start = '${j['start'] ?? start}';
    switchHour = (j['switchHour'] as num?)?.toInt() ?? switchHour;
    onboarded = j['onboarded'] == true;
    offsets = {};
    final om = (j['offsets'] as Map?) ?? {};
    om.forEach((k, v) {
      offsets['$k'] = (v as num).toInt();
    });
    skips = ((j['skips'] as List?) ?? []).map((e) => '$e').toSet();
    holidays = ((j['holidays'] as List?) ?? []).map((e) => '$e').toList();
    edits = Map<String, dynamic>.from((j['edits'] as Map?) ?? {});
    refl = {};
    final rm = (j['refl'] as Map?) ?? {};
    rm.forEach((k, v) {
      final inner = <String, String>{};
      (v as Map).forEach((a, b) {
        inner['$a'] = '$b';
      });
      refl['$k'] = inner;
    });
    done = ((j['done'] as List?) ?? []).map((e) => '$e').toSet();
  }

  Map<String, dynamic> toJson() => {
        'app': 'lesson_planner',
        'v': 1,
        'teacher': teacher,
        'school': school,
        'start': start,
        'switchHour': switchHour,
        'onboarded': onboarded,
        'offsets': offsets,
        'skips': skips.toList(),
        'holidays': holidays,
        'edits': edits,
        'refl': refl,
        'done': done.toList(),
      };

  Future<void> save() async {
    try {
      await _db?.saveState(jsonEncode(toJson()));
    } catch (e) {
      // تجاهل
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), save);
  }

  void touch() {
    notifyListeners();
    _schedule();
  }

  void touchQuiet() {
    _schedule();
  }

  // ---------- المنهج ----------
  bool hasPlan(int g) => (cur['g'] as Map).containsKey('$g');

  Map<String, dynamic> weekInfo(int g, int weekIndex) {
    final gm = (cur['g'] as Map)['$g'] as Map;
    return Map<String, dynamic>.from((gm['w'] as List)[weekIndex] as Map);
  }

  Lesson baseLesson(int g, int k) {
    final w = weekInfo(g, k ~/ 2);
    final s = Map<String, dynamic>.from((w['s'] as List)[k % 2] as Map);
    s['topic'] = w['t'];
    return Lesson.fromJson(s);
  }

  Lesson lessonFor(int g, int k) {
    final key = 'L:$g:$k';
    if (edits.containsKey(key)) {
      try {
        return Lesson.fromJson(Map<String, dynamic>.from(edits[key] as Map));
      } catch (e) {
        // نعود للأصل إذا كان المحفوظ تالفاً
      }
    }
    return baseLesson(g, k);
  }

  bool isEdited(int g, int k) => edits.containsKey('L:$g:$k');

  // ---------- ربط التاريخ بالدرس ----------
  Ctx buildCtx(Slot s, DateTime date) {
    final cls = s.cls;
    var count = 0;
    var d = parseDate(start);
    while (d.isBefore(date)) {
      final di = dayIdx(d);
      if (di <= 4 && !holidays.contains(fmt(d))) {
        for (final x in kTimetable) {
          if (x.day == di && x.cls == cls && !skips.contains('${fmt(d)}|${x.p}')) {
            count++;
          }
        }
      }
      d = d.add(const Duration(days: 1));
    }
    final skipped = skips.contains('${fmt(date)}|${s.p}');
    final k = count + (offsets[cls] ?? 0);
    return Ctx(s, date, k, skipped);
  }

  bool isHoliday(DateTime d) => holidays.contains(fmt(d));

  List<Ctx> ctxFor(DateTime date) {
    final res = <Ctx>[];
    final di = dayIdx(date);
    if (di > 4 || isHoliday(date)) return res;
    final slots = kTimetable.where((s) => s.day == di).toList();
    slots.sort((a, b) => a.p.compareTo(b.p));
    for (final s in slots) {
      res.add(buildCtx(s, date));
    }
    return res;
  }
}
