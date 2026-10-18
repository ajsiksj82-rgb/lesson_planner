import 'package:flutter_test/flutter_test.dart';
import 'package:lesson_planner/models/models.dart';

void main() {
  test('Lesson json round-trip مع تجاوز الدقائق', () {
    final l = Lesson('موضوع', 'الحصة الأولى', [Goal('هدف', 'معرفي', 'فهم')], [Item('م', 'ن', 'ل', 'حوار', 2, m35: 9)], 'مصادر', 'تقويم');
    final r = Lesson.fromJson(l.toJson());
    expect(r.topic, 'موضوع');
    expect(r.items.first.m35, 9);
    expect(r.items.first.m45, isNull);
    expect(r.minutes(35), [9]);
    expect(r.minutes(45), [45]);
  });

  test('Lesson.blank جاهز للتحرير اليدوي', () {
    final b = Lesson.blank();
    expect(b.goals.length, 2);
    expect(b.items.length, 1);
  });
}
