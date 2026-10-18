import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/data/timetable.dart';
import 'package:lesson_planner/screens/backup_screen.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';
import 'package:lesson_planner/widgets/common.dart';

// ============================================================
//                        صفحة الإعدادات
// ============================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController teacherC = TextEditingController(text: Store.I.teacher);
  final TextEditingController schoolC = TextEditingController(text: Store.I.school);

  @override
  void dispose() {
    teacherC.dispose();
    schoolC.dispose();
    super.dispose();
  }

  Widget _box(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final classes = allClasses();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Text('الإعدادات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _box('البيانات العامة', [
            FieldBox(label: 'اسم المدرس', ctrl: teacherC, minLines: 1, copy: false, onChanged: (v) {
              st.teacher = v;
              st.touchQuiet();
            }),
            FieldBox(label: 'اسم المدرسة', ctrl: schoolC, minLines: 1, copy: false, onChanged: (v) {
              st.school = v;
              st.touchQuiet();
            }),
          ]),
          _box('بداية التدريس والعرض', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تاريخ أول حصة مُحتسبة'),
              subtitle: Text(longDate(parseDate(st.start))),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final r = await pickDate(context, parseDate(st.start));
                if (r != null) {
                  st.start = fmt(r);
                  st.touch();
                }
              },
            ),
            const Text('يبدأ عدّ الدروس لكل شعبة من هذا التاريخ. إن بدأت حصة السبت 17 أكتوبر فاختر 17 أكتوبر.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            Row(children: [
              const Expanded(child: Text('الانتقال تلقائياً إلى تحضير الغد بعد الساعة')),
              DropdownButton<int>(
                value: st.switchHour,
                items: [for (var h = 11; h <= 22; h++) DropdownMenuItem<int>(value: h, child: Text('$h:00'))],
                onChanged: (v) {
                  st.switchHour = v ?? st.switchHour;
                  st.touch();
                },
              ),
            ]),
          ]),
          _box('إزاحة الدروس لكل شعبة', [
            const Text('إذا تقدمت شعبة أو تأخرت عن غيرها فاضبط الإزاحة بالحصص (+ للتقديم، − للتأخير). كل أسبوع = حصتان.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            for (final c in classes)
              Row(children: [
                Expanded(child: Text('الشعبة $c')),
                IconButton(
                  onPressed: () {
                    st.offsets[c] = (st.offsets[c] ?? 0) - 1;
                    st.touch();
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(width: 34, child: Center(child: Text('${st.offsets[c] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)))),
                IconButton(
                  onPressed: () {
                    st.offsets[c] = (st.offsets[c] ?? 0) + 1;
                    st.touch();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ]),
          ]),
          _box('العطل والأيام الملغاة', [
            if (st.holidays.isEmpty) const Text('لا توجد عطل مسجلة.', style: TextStyle(color: Colors.black54)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final h in st.holidays)
                InputChip(
                  label: Text(longDate(parseDate(h))),
                  onDeleted: () {
                    st.holidays.remove(h);
                    st.touch();
                  },
                ),
            ]),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                final r = await pickDate(context, nextTeachingDay(todayDate()));
                if (r != null && !st.holidays.contains(fmt(r))) {
                  st.holidays.add(fmt(r));
                  st.holidays.sort();
                  st.touch();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة يوم عطلة (لا دروس لكل الشعب)'),
            ),
            const SizedBox(height: 10),
            Text('حصص لم تُعقد: ${st.skips.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final k in (st.skips.toList()..sort()))
                InputChip(
                  label: Text(_skipLabel(k)),
                  onDeleted: () {
                    st.skips.remove(k);
                    st.touch();
                  },
                ),
            ]),
          ]),
          _box('النسخ الاحتياطي', [
            const Text('تعديلاتك محفوظة داخل الجهاز. انسخ نسخة احتياطية واحفظها في مكان آمن قبل حذف التطبيق أو مسح بياناته.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => copyText(context, jsonEncode(st.toJson()), msg: 'تم نسخ النسخة الاحتياطية — الصقها في ملاحظات أو رسالة'),
                  icon: const Icon(Icons.copy_all),
                  label: const Text('نسخ نسخة احتياطية'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importDialog(context),
                  icon: const Icon(Icons.restore),
                  label: const Text('استرجاع'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
              icon: const Icon(Icons.folder_open),
              label: const Text('النسخ الاحتياطي بالملفات'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _resetDialog(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('حذف كل تعديلاتي على التحضيرات', style: TextStyle(color: Colors.red)),
            ),
          ]),
          _box('عن التطبيق', [
            const Text('مخطط التحضير الذكي — يجهّز لك تحضير كل حصة حسب جدولك وخطط الصفوف، بحصتين أسبوعياً لكل شعبة (شرح ثم تطبيق).'),
            const SizedBox(height: 6),
            Text('إعداد وتطوير: ${st.teacher}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('ملاحظة: خطة الصف التاسع مقترحة (لا يوجد منهج رسمي) ويمكنك تعديلها كلياً.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ],
      ),
    );
  }

  String _skipLabel(String key) {
    try {
      final parts = key.split('|');
      final d = parseDate(parts[0]);
      final p = int.parse(parts[1]);
      String cls = '';
      for (final s in kTimetable) {
        if (s.day == dayIdx(d) && s.p == p) cls = s.cls;
      }
      return '${kDayNames[dayIdx(d)]} ${d.day} ${kMonths[d.month - 1]} — حصة $p — $cls';
    } catch (e) {
      return key;
    }
  }

  Future<void> _importDialog(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استرجاع نسخة احتياطية'),
        content: TextField(controller: c, maxLines: 6, decoration: const InputDecoration(hintText: 'الصق النسخة الاحتياطية هنا', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استرجاع')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final m = jsonDecode(c.text.trim());
        final err = Store.validateState(m);
        if (err != null) {
          if (context.mounted) toast(context, err);
          c.dispose();
          return;
        }
        Store.I.fromJson(m as Map<String, dynamic>);
        Store.I.touch();
        teacherC.text = Store.I.teacher;
        schoolC.text = Store.I.school;
        if (context.mounted) toast(context, 'تم استرجاع النسخة الاحتياطية');
      } catch (e) {
        if (context.mounted) toast(context, 'النص ليس نسخة احتياطية صالحة');
      }
    }
    c.dispose();
  }

  Future<void> _resetDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('سيتم حذف تعديلاتك على التحضيرات وملاحظات التأمل، وتبقى الإعدادات والعطل. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      Store.I.edits = {};
      Store.I.refl = {};
      Store.I.touch();
      if (context.mounted) toast(context, 'تم الحذف');
    }
  }
}

