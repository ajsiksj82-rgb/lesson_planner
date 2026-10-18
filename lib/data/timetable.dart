

// ---------- الجدول الأسبوعي (جدول شريف أحمد) ----------
// day: 0=السبت 1=الأحد 2=الاثنين 3=الثلاثاء 4=الأربعاء ، p = رقم الحصة
class Slot {
  final int day;
  final int p;
  final int g;
  final String sec;
  const Slot(this.day, this.p, this.g, this.sec);
  String get cls => '$g$sec';
}

const List<Slot> kTimetable = [
  // السبت
  Slot(0, 1, 9, 'أ'),
  Slot(0, 2, 8, 'ج'),
  Slot(0, 3, 5, 'ب'),
  Slot(0, 5, 9, 'ب'),
  Slot(0, 7, 5, 'أ'),
  // الأحد
  Slot(1, 3, 5, 'ج'),
  Slot(1, 4, 4, 'ب'),
  Slot(1, 5, 5, 'أ'),
  Slot(1, 6, 9, 'أ'),
  Slot(1, 7, 4, 'ج'),
  // الاثنين
  Slot(2, 1, 5, 'ب'),
  Slot(2, 2, 9, 'ج'),
  Slot(2, 4, 8, 'ج'),
  // الثلاثاء
  Slot(3, 1, 4, 'أ'),
  Slot(3, 2, 9, 'ج'),
  Slot(3, 3, 12, 'ب'),
  Slot(3, 6, 4, 'ب'),
  // الأربعاء
  Slot(4, 2, 5, 'ج'),
  Slot(4, 3, 4, 'أ'),
  Slot(4, 5, 9, 'ب'),
  Slot(4, 6, 4, 'ج'),
];

List<String> allClasses() {
  final seen = <String>{};
  final out = <Slot>[];
  for (final s in kTimetable) {
    if (seen.add(s.cls)) out.add(s);
  }
  out.sort((a, b) {
    final c = a.g.compareTo(b.g);
    return c != 0 ? c : a.sec.compareTo(b.sec);
  });
  return out.map((e) => e.cls).toList();
}
