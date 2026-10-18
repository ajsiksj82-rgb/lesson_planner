import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/screens/lesson_screen.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';

// ============================================================
//                       صفحة الدروس (المكتبة)
// ============================================================
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final gm = st.cur['g'] as Map;
    final keys = gm.keys.map((e) => int.parse('$e')).toList()..sort();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('مكتبة الدروس', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('كل الأسابيع الأربعة عشر لكل صف، بحصتين أسبوعياً.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          for (final g in keys)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(radius: 26, backgroundColor: kGradeColors[g], child: Text('$g', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))),
                title: Text('الصف ${kGradeNames[g]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${(gm['$g'] as Map)['tag']}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GradePage(grade: g))),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
            child: const Text('الصف الثاني عشر (12ب) ليس له خطة فصلية؛ يمكنك إنشاء تحضير يدوي من صفحة «اليوم».', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class GradePage extends StatelessWidget {
  final int grade;
  const GradePage({super.key, required this.grade});
  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    return Scaffold(
      appBar: AppBar(title: Text('الصف ${kGradeNames[grade]}'), centerTitle: true, backgroundColor: kPrimary, foregroundColor: Colors.white),
      body: AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 14,
        itemBuilder: (context, w) {
          final info = st.weekInfo(grade, w);
          final from = kTermStart.add(Duration(days: 7 * w));
          final to = from.add(const Duration(days: 4));
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 15, backgroundColor: kPrimary, child: Text('${w + 1}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                const SizedBox(width: 8),
                Expanded(child: Text('${info['t']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ]),
              const SizedBox(height: 4),
              Text('${shortDate(from)} – ${shortDate(to)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPage(grade: grade, k: w * 2, dur: 45))),
                    child: Text(st.isEdited(grade, w * 2) ? 'الحصة 1 (معدّلة)' : 'الحصة 1: شرح'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPage(grade: grade, k: w * 2 + 1, dur: 45))),
                    child: Text(st.isEdited(grade, w * 2 + 1) ? 'الحصة 2 (معدّلة)' : 'الحصة 2: تطبيق'),
                  ),
                ),
              ]),
            ]),
          );
        },
        ),
      ),
    );
  }
}

