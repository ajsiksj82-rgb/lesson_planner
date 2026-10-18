

import 'package:lesson_planner/data/timetable.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';

// ---------- النماذج ----------
class Goal {
  String t;
  String d;
  String l;
  Goal(this.t, this.d, this.l);
  factory Goal.fromJson(Map<String, dynamic> j) => Goal('${j['t']}', '${j['d']}', '${j['l']}');
  Map<String, dynamic> toJson() => {'t': t, 'd': d, 'l': l};
}

class Item {
  String c;
  String t;
  String l;
  String s;
  int w;
  int? m35;
  int? m45;
  Item(this.c, this.t, this.l, this.s, this.w, {this.m35, this.m45});
  factory Item.fromJson(Map<String, dynamic> j) => Item(
        '${j['c']}',
        '${j['t']}',
        '${j['l']}',
        '${j['s']}',
        (j['w'] as num?)?.toInt() ?? 1,
        m35: (j['m35'] as num?)?.toInt(),
        m45: (j['m45'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = {'c': c, 't': t, 'l': l, 's': s, 'w': w};
    if (m35 != null) m['m35'] = m35;
    if (m45 != null) m['m45'] = m45;
    return m;
  }
}

class Lesson {
  String topic;
  String sub;
  List<Goal> goals;
  List<Item> items;
  String res;
  String ev;
  Lesson(this.topic, this.sub, this.goals, this.items, this.res, this.ev);

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        '${j['topic']}',
        '${j['sub']}',
        (j['goals'] as List).map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        (j['items'] as List).map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        '${j['res']}',
        '${j['ev']}',
      );

  factory Lesson.blank() => Lesson(
        '',
        '',
        [Goal('', 'معرفي', 'تذكر'), Goal('', 'مهاري', 'تطبيق')],
        [Item('', '', '', '', 1)],
        '',
        '',
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'sub': sub,
        'goals': goals.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'res': res,
        'ev': ev,
      };

  List<int> minutes(int dur) {
    final comp = distribute(items.map((e) => e.w).toList(), dur);
    return List<int>.generate(items.length, (i) {
      final o = dur == 35 ? items[i].m35 : items[i].m45;
      return o ?? comp[i];
    });
  }
}

// سياق حصة محددة (شعبة + تاريخ)
class Ctx {
  final Slot slot;
  final DateTime date;
  final int k; // رقم الحصة ضمن تسلسل الشعبة (0..27) أو سالب/كبير خارج الخطة
  final bool skipped;
  Ctx(this.slot, this.date, this.k, this.skipped);
  int get dur => durationOfDay(dayIdx(date));
  String get key => '${fmt(date)}|${slot.p}';
  int get planWeek => k ~/ 2 + 1;
  int get session => k % 2 + 1;
  bool get inRange => k >= 0 && k < kSessionsPerClass;
}
