import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/data/timetable.dart';
import 'package:lesson_planner/screens/lesson_screen.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';

// ============================================================
//                        صفحة الجدول
// ============================================================
class WeekPage extends StatefulWidget {
  const WeekPage({super.key});
  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  DateTime base = weekStart(nextTeachingDay(todayDate()));

  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final end = base.add(const Duration(days: 4));
    final wk = weekOfTerm(base);
    final today = todayDate();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => base = base.subtract(const Duration(days: 7))), icon: const Icon(Icons.chevron_right)),
            Expanded(
              child: Column(children: [
                Text(wk >= 1 && wk <= 14 ? 'الأسبوع $wk' : 'خارج أسابيع الفصل', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${shortDate(base)} – ${shortDate(end)} ${end.year}', style: const TextStyle(color: Colors.black54)),
              ]),
            ),
            IconButton(onPressed: () => setState(() => base = base.add(const Duration(days: 7))), icon: const Icon(Icons.chevron_left)),
          ]),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(6),
            child: Table(
              columnWidths: const {0: FixedColumnWidth(58)},
              defaultColumnWidth: const FlexColumnWidth(),
              border: TableBorder.all(color: const Color(0xFFE0E0E0)),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFE0F2F1)),
                  children: [
                    const SizedBox(height: 32),
                    for (var p = 1; p <= 7; p++) Center(child: Text('$p', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                for (var d = 0; d <= 4; d++) _row(context, st, d, today),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final g in [4, 5, 8, 9, 12])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kGradeColors[g], borderRadius: BorderRadius.circular(10)),
                child: Text(kGradeNames[g] ?? '', style: const TextStyle(fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 8),
          const Text('اضغط على أي حصة لفتح تحضيرها. السبت والأحد: 35 دقيقة، وبقية الأيام: 45 دقيقة.', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
        ],
      ),
    );
  }

  TableRow _row(BuildContext context, Store st, int d, DateTime today) {
    final date = base.add(Duration(days: d));
    final isToday = fmt(date) == fmt(today);
    final cells = <Widget>[
      Container(
        height: 52,
        color: isToday ? const Color(0xFFFFF59D) : const Color(0xFFF5F5F5),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(kDayNames[d], style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          Text('${date.day}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ]),
      ),
    ];
    for (var p = 1; p <= 7; p++) {
      Slot? slot;
      for (final s in kTimetable) {
        if (s.day == d && s.p == p) slot = s;
      }
      if (slot == null) {
        cells.add(const SizedBox(height: 52));
      } else {
        final s2 = slot;
        final c = st.buildCtx(s2, date);
        final isDone = st.done.contains(c.key);
        cells.add(InkWell(
          onTap: () => openCtx(context, c),
          child: Container(
            height: 52,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(color: c.skipped ? Colors.grey.shade300 : (kGradeColors[s2.g] ?? Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s2.cls, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, decoration: c.skipped ? TextDecoration.lineThrough : null)),
              if (isDone) const Icon(Icons.check_circle, size: 12, color: Color(0xFF2E7D32)),
            ]),
          ),
        ));
      }
    }
    return TableRow(children: cells);
  }
}

