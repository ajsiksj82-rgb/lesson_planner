

import 'package:lesson_planner/utils/constants.dart';

// ---------- أدوات التاريخ ----------
DateTime todayDate() {
  final n = DateTime.now();
  return DateTime.utc(n.year, n.month, n.day);
}

String fmt(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$dd';
}

DateTime parseDate(String s) {
  try {
    final p = s.split('-');
    return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  } catch (e) {
    return DateTime.utc(2026, 10, 17);
  }
}

// 0=السبت ... 4=الأربعاء ، 5=الخميس ، 6=الجمعة
int dayIdx(DateTime d) => (d.weekday + 1) % 7;

String longDate(DateTime d) => '${kDayNames[dayIdx(d)]} ${d.day} ${kMonths[d.month - 1]} ${d.year}';
String shortDate(DateTime d) => '${d.day} ${kMonths[d.month - 1]}';

// رقم الأسبوع حسب الخطة الفصلية
int weekOfTerm(DateTime d) => (d.difference(kTermStart).inDays / 7).floor() + 1;

// أول سبت في أسبوع التاريخ
DateTime weekStart(DateTime d) {
  final di = dayIdx(d); // السبت=0
  return d.subtract(Duration(days: di));
}

DateTime nextTeachingDay(DateTime d) {
  var x = d;
  while (dayIdx(x) > 4) {
    x = x.add(const Duration(days: 1));
  }
  return x;
}

// مدة الحصة: 35 دقيقة السبت والأحد، 45 دقيقة بقية الأيام
int durationOfDay(int day) => day <= 1 ? 35 : 45;

// توزيع الدقائق على العناصر حسب الأوزان بطريقة أكبر باقي (مجموعها = المدة بالضبط)
List<int> distribute(List<int> w, int total) {
  final sum = w.fold<int>(0, (a, b) => a + b);
  if (sum <= 0) return List<int>.filled(w.length, 0);
  final base = <int>[];
  final rem = <double>[];
  var used = 0;
  for (final x in w) {
    final v = total * x / sum;
    final f = v.floor();
    base.add(f);
    rem.add(v - f);
    used += f;
  }
  var left = total - used;
  final order = List<int>.generate(w.length, (i) => i);
  order.sort((a, b) => rem[b].compareTo(rem[a]));
  var i = 0;
  while (left > 0) {
    base[order[i % order.length]]++;
    left--;
    i++;
  }
  return base;
}
