import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/models/models.dart';
import 'package:lesson_planner/screens/lesson_screen.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';
import 'package:lesson_planner/widgets/common.dart';

// ============================================================
//                         صفحة اليوم
// ============================================================
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  DateTime? sel;

  DateTime _auto() {
    final now = DateTime.now();
    var d = todayDate();
    if (now.hour >= Store.I.switchHour) d = d.add(const Duration(days: 1));
    return nextTeachingDay(d);
  }

  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final date = sel ?? _auto();
    final today = todayDate();
    final tomorrow = nextTeachingDay(today.add(const Duration(days: 1)));
    final list = st.ctxFor(date);
    final di = dayIdx(date);
    final wk = weekOfTerm(date);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0E7C66), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.school, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text('تحضير ${kDayNames[di]}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(longDate(date), style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _pill(wk >= 1 && wk <= 14 ? 'الأسبوع $wk من 14' : 'خارج أسابيع الفصل'),
                _pill(di <= 1 ? 'مدة الحصة 35 دقيقة' : (di <= 4 ? 'مدة الحصة 45 دقيقة' : 'عطلة أسبوعية')),
                _pill('${list.length} حصص'),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ChoiceChip(label: const Text('اليوم'), selected: fmt(date) == fmt(today), onSelected: (_) => setState(() => sel = today)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('الغد'), selected: fmt(date) == fmt(tomorrow) && fmt(date) != fmt(today), onSelected: (_) => setState(() => sel = tomorrow)),
            const Spacer(),
            IconButton(tooltip: 'اليوم التالي', onPressed: () => setState(() => sel = nextTeachingDay(date.add(const Duration(days: 1)))), icon: const Icon(Icons.chevron_left)),
            IconButton(
              tooltip: 'اليوم السابق',
              onPressed: () {
                var x = date.subtract(const Duration(days: 1));
                while (dayIdx(x) > 4) {
                  x = x.subtract(const Duration(days: 1));
                }
                setState(() => sel = x);
              },
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'اختيار تاريخ',
              onPressed: () async {
                final r = await pickDate(context, date);
                if (r != null) setState(() => sel = r);
              },
              icon: const Icon(Icons.edit_calendar),
            ),
          ]),
          const SizedBox(height: 4),
          if (di > 4)
            _note('هذا اليوم عطلة أسبوعية (الخميس والجمعة).')
          else if (st.isHoliday(date))
            _note('هذا اليوم مسجل كعطلة في الإعدادات.')
          else if (list.isEmpty)
            _note('لا توجد حصص لك في هذا اليوم.')
          else
            ...list.map((c) => _card(context, c)),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _note(String t) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Text(t, style: const TextStyle(fontSize: 15, color: Colors.black54)),
      );

  Widget _card(BuildContext context, Ctx c) {
    final st = Store.I;
    final g = c.slot.g;
    final plan = st.hasPlan(g);
    final isDone = st.done.contains(c.key);
    String title;
    String sub;
    if (c.skipped) {
      title = 'لم تُعقد هذه الحصة';
      sub = 'سينتقل درسها إلى الحصة التالية لهذه الشعبة.';
    } else if (!plan) {
      title = 'لا توجد خطة لهذا الصف';
      sub = 'اضغط لإنشاء تحضير يدوي.';
    } else if (!c.inRange) {
      title = c.k < 0 ? 'قبل بداية الخطة' : 'انتهت دروس الخطة';
      sub = c.k < 0 ? 'راجع تاريخ بدء التدريس في الإعدادات.' : 'لا يوجد درس مجدول بعد الأسبوع 14.';
    } else {
      final L = st.lessonFor(g, c.k);
      title = L.topic;
      sub = 'الأسبوع ${c.planWeek} — ${c.session == 1 ? 'الحصة الأولى: شرح وعرض' : 'الحصة الثانية: تطبيق وتدريب'}';
    }
    final cal = weekOfTerm(c.date);
    String? lag;
    if (plan && c.inRange && !c.skipped && cal >= 1 && cal <= 14) {
      if (c.planWeek < cal) {
        lag = 'متأخر عن الخطة ${cal - c.planWeek} أسبوع';
      } else if (c.planWeek > cal) {
        lag = 'متقدم على الخطة ${c.planWeek - cal} أسبوع';
      }
    }
    return Opacity(
      opacity: c.skipped ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openCtx(context, c),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: kGradeColors[g] ?? Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text('${c.slot.p}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('الحصة', style: TextStyle(fontSize: 10.5)),
                  const SizedBox(height: 4),
                  Text(c.slot.cls, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${kGradeNames[g] ?? ''} — شعبة ${c.slot.sec}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _chip('${c.dur} دقيقة', Colors.blueGrey.shade50),
                    if (isDone) _chip('تم الإدخال ✓', const Color(0xFFC8E6C9)),
                    if (plan && c.inRange && st.isEdited(g, c.k)) _chip('معدّل', const Color(0xFFFFE0B2)),
                    if (lag != null) _chip(lag, const Color(0xFFFFCDD2)),
                  ]),
                ]),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'skip') {
                    st.skips.add(c.key);
                  } else if (v == 'restore') {
                    st.skips.remove(c.key);
                  } else if (v == 'done') {
                    if (isDone) {
                      st.done.remove(c.key);
                    } else {
                      st.done.add(c.key);
                    }
                  }
                  st.touch();
                },
                itemBuilder: (_) => [
                  if (!c.skipped) const PopupMenuItem(value: 'skip', child: Text('لم تُعقد الحصة (تأجيل الدرس)')),
                  if (c.skipped) const PopupMenuItem(value: 'restore', child: Text('استعادة الحصة')),
                  if (!c.skipped) PopupMenuItem(value: 'done', child: Text(isDone ? 'إلغاء علامة «تم الإدخال»' : 'تم إدخالها في تطبيق التحضير')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontSize: 11.5)),
      );
}

