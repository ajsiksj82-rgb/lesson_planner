

import 'package:lesson_planner/models/models.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';

// ---------- نص التحضير الكامل للنسخ ----------
String lessonText(Lesson L, int dur, {Ctx? ctx, int? grade, String refl1 = '', String refl2 = ''}) {
  final b = StringBuffer();
  b.writeln('نموذج تحضير الدروس');
  if (ctx != null) {
    b.writeln('اليوم: ${kDayNames[dayIdx(ctx.date)]}');
    b.writeln('التاريخ: ${fmt(ctx.date)}');
    b.writeln('الحصة: ${ctx.slot.p}');
    b.writeln('الصف: ${kGradeNames[ctx.slot.g] ?? ''}');
    b.writeln('الشعبة: ${ctx.slot.sec}');
  } else if (grade != null) {
    b.writeln('الصف: ${kGradeNames[grade] ?? ''}');
  }
  b.writeln('المادة: الحاسوب');
  b.writeln('الموضوع: ${L.topic}${L.sub.isEmpty ? '' : ' (${L.sub})'}');
  b.writeln('');
  b.writeln('الأهداف التعليمية:');
  for (var i = 0; i < L.goals.length; i++) {
    final g = L.goals[i];
    b.writeln('${i + 1}) ${g.t}  [المجال: ${g.d} – المستوى: ${g.l}]');
  }
  b.writeln('');
  b.writeln('تنفيذ الدرس:');
  final mins = L.minutes(dur);
  for (var i = 0; i < L.items.length; i++) {
    final it = L.items[i];
    b.writeln('عنصر المحتوى ${i + 1}:');
    b.writeln('  المحتوى/المادة العلمية: ${it.c}');
    b.writeln('  نشاط المعلم: ${it.t}');
    b.writeln('  نشاط المتعلم: ${it.l}');
    b.writeln('  الزمن: ${mins[i]} دقيقة');
    b.writeln('  استراتيجيات التدريس: ${it.s}');
  }
  b.writeln('');
  b.writeln('مصادر التعلم والوسائل المستخدمة: ${L.res}');
  b.writeln('التقويم الختامي والواجب البيتي: ${L.ev}');
  if (refl1.trim().isNotEmpty) b.writeln('التأمل الذاتي للمعلم: $refl1');
  if (refl2.trim().isNotEmpty) b.writeln('طموح تطوير الذات: $refl2');
  return b.toString();
}
