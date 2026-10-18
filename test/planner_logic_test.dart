import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/data/curriculum_data.dart';
import 'package:lesson_planner/data/timetable.dart';
import 'package:lesson_planner/models/models.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';
import 'package:lesson_planner/utils/lesson_text.dart';

Slot slotOf(String cls, int day) => kTimetable.firstWhere((s) => s.cls == cls && s.day == day);

void resetStore() {
  final st = Store.I;
  st.cur = jsonDecode(kCurriculum) as Map<String, dynamic>;
  st.start = '2026-10-18';
  st.offsets = {};
  st.skips = {};
  st.holidays = [];
  st.edits = {};
  st.refl = {};
  st.done = {};
}

void main() {
  setUp(resetStore);

  group('التواريخ', () {
    test('ترتيب الأيام: السبت=0 والأربعاء=4', () {
      expect(dayIdx(DateTime.utc(2026, 10, 17)), 0); // السبت
      expect(dayIdx(DateTime.utc(2026, 10, 18)), 1); // الأحد
      expect(dayIdx(DateTime.utc(2026, 10, 21)), 4); // الأربعاء
      expect(dayIdx(DateTime.utc(2026, 10, 22)), 5); // الخميس
      expect(dayIdx(DateTime.utc(2026, 10, 23)), 6); // الجمعة
    });

    test('مدة الحصة: 35 للسبت والأحد و45 لبقية الأيام', () {
      expect(durationOfDay(0), 35);
      expect(durationOfDay(1), 35);
      for (var d = 2; d <= 4; d++) {
        expect(durationOfDay(d), 45);
      }
    });

    test('nextTeachingDay يتجاوز الخميس والجمعة', () {
      expect(dayIdx(nextTeachingDay(DateTime.utc(2026, 10, 22))), 0);
      expect(dayIdx(nextTeachingDay(DateTime.utc(2026, 10, 23))), 0);
    });

    test('fmt و parseDate', () {
      expect(fmt(DateTime.utc(2026, 1, 5)), '2026-01-05');
      expect(parseDate('2026-10-17'), DateTime.utc(2026, 10, 17));
      expect(parseDate('خطأ'), DateTime.utc(2026, 10, 17));
    });
  });

  group('الجدول', () {
    test('21 حصة بلا تكرار لليوم والحصة', () {
      expect(kTimetable.length, 21);
      final keys = kTimetable.map((s) => '${s.day}|${s.p}').toSet();
      expect(keys.length, 21);
    });

    test('الشعب المدرَّسة', () {
      expect(allClasses(), ['4أ', '4ب', '4ج', '5أ', '5ب', '5ج', '8ج', '9أ', '9ب', '9ج', '12ب']);
    });
  });

  group('توزيع الدقائق', () {
    test('المجموع يساوي مدة الحصة تماماً لكل تحضير', () {
      final cur = Store.I.cur;
      var n = 0;
      for (final g in (cur['g'] as Map).values) {
        for (final w in (g as Map)['w'] as List) {
          for (final s in (w as Map)['s'] as List) {
            final items = (s as Map)['items'] as List;
            final ws = items.map((e) => ((e as Map)['w'] as num).toInt()).toList();
            for (final t in [35, 45]) {
              final m = distribute(ws, t);
              expect(m.fold<int>(0, (a, b) => a + b), t);
              expect(m.every((x) => x >= 1), isTrue);
            }
            n++;
          }
        }
      }
      expect(n, 112);
    });

    test('45 دقيقة بأوزان 2/4/3 = 10/20/15', () {
      expect(distribute([2, 4, 3], 45), [10, 20, 15]);
      expect(distribute([2, 4, 3], 35), [8, 15, 12]);
    });
  });

  group('المنهج', () {
    test('4 صفوف × 14 أسبوعاً × حصتان', () {
      final st = Store.I;
      for (final g in [4, 5, 8, 9]) {
        expect(st.hasPlan(g), isTrue);
        for (var k = 0; k < kSessionsPerClass; k++) {
          final l = st.baseLesson(g, k);
          expect(l.topic.isNotEmpty, isTrue);
          expect(l.items.length, 3);
          expect(l.goals.length, 2);
          for (final goal in l.goals) {
            expect(kLevels[goal.d]!.contains(goal.l), isTrue, reason: '$g/$k ${goal.d}/${goal.l}');
          }
        }
      }
      expect(st.hasPlan(12), isFalse);
    });

    test('نص النسخ يحتوي الحقول الأساسية', () {
      final l = Store.I.baseLesson(4, 0);
      final txt = lessonText(l, 35);
      for (final k in ['الموضوع:', 'الأهداف التعليمية:', 'نشاط المعلم:', 'نشاط المتعلم:', 'الزمن:', 'استراتيجيات التدريس:', 'التقويم الختامي والواجب البيتي:']) {
        expect(txt.contains(k), isTrue, reason: k);
      }
    });
  });

  group('ربط التاريخ بالدرس', () {
    test('تسلسل الشعبة 4ب: الأحد 18 ثم الثلاثاء 20 ثم الأحد 25', () {
      final st = Store.I;
      expect(st.buildCtx(slotOf('4ب', 1), DateTime.utc(2026, 10, 18)).k, 0);
      expect(st.buildCtx(slotOf('4ب', 3), DateTime.utc(2026, 10, 20)).k, 1);
      expect(st.buildCtx(slotOf('4ب', 1), DateTime.utc(2026, 10, 25)).k, 2);
    });

    test('بدء الفصل من السبت 17 يزيح التسلسل', () {
      final st = Store.I..start = '2026-10-17';
      // 5ب: السبت 17 حصة 3 → k=0 ، الاثنين 19 → k=1
      expect(st.buildCtx(slotOf('5ب', 0), DateTime.utc(2026, 10, 17)).k, 0);
      expect(st.buildCtx(slotOf('5ب', 2), DateTime.utc(2026, 10, 19)).k, 1);
    });

    test('العطلة تُزيح الدروس التالية', () {
      final st = Store.I..holidays = ['2026-10-20'];
      expect(st.buildCtx(slotOf('4ب', 1), DateTime.utc(2026, 10, 25)).k, 1);
      expect(st.ctxFor(DateTime.utc(2026, 10, 20)), isEmpty);
    });

    test('الحصة التي لم تُعقد تُزيح المحتوى للحصة التالية', () {
      final st = Store.I..skips = {'2026-10-18|4'};
      expect(st.buildCtx(slotOf('4ب', 3), DateTime.utc(2026, 10, 20)).k, 0);
      expect(st.buildCtx(slotOf('4ب', 1), DateTime.utc(2026, 10, 18)).skipped, isTrue);
    });

    test('الإزاحة اليدوية للشعبة', () {
      final st = Store.I..offsets = {'4ب': 3};
      expect(st.buildCtx(slotOf('4ب', 1), DateTime.utc(2026, 10, 18)).k, 3);
    });

    test('الخميس والجمعة بلا حصص', () {
      expect(Store.I.ctxFor(DateTime.utc(2026, 10, 22)), isEmpty);
      expect(Store.I.ctxFor(DateTime.utc(2026, 10, 23)), isEmpty);
    });

    test('أسبوع الخطة والحصة داخل الأسبوع', () {
      final c = Ctx(slotOf('4ب', 1), DateTime.utc(2026, 10, 18), 5, false);
      expect(c.planWeek, 3);
      expect(c.session, 2);
      expect(c.inRange, isTrue);
      expect(Ctx(slotOf('4ب', 1), DateTime.utc(2026, 10, 18), 28, false).inRange, isFalse);
    });

    test('آخر حصة في الفصل (20 يناير 2027) ضمن الأسابيع 14', () {
      // أسبوع 14 يبدأ السبت 16 يناير 2027
      expect(weekOfTerm(DateTime.utc(2027, 1, 20)), 14);
    });
  });

  group('التعديلات والنسخ الاحتياطي', () {
    test('التعديل المحفوظ يُستخدم بدل الأصل ثم يُستعاد', () {
      final st = Store.I;
      final l = st.baseLesson(4, 0)..topic = 'موضوع معدّل';
      st.edits['L:4:0'] = l.toJson();
      expect(st.lessonFor(4, 0).topic, 'موضوع معدّل');
      expect(st.isEdited(4, 0), isTrue);
      st.edits.remove('L:4:0');
      expect(st.lessonFor(4, 0).topic, isNot('موضوع معدّل'));
    });

    test('toJson/fromJson يحفظان الحالة', () {
      final st = Store.I
        ..offsets = {'4أ': 2}
        ..skips = {'2026-10-18|4'}
        ..holidays = ['2026-11-01']
        ..done = {'x'};
      final j = jsonDecode(jsonEncode(st.toJson())) as Map<String, dynamic>;
      st
        ..offsets = {}
        ..skips = {}
        ..holidays = []
        ..done = {};
      st.fromJson(j);
      expect(st.offsets, {'4أ': 2});
      expect(st.skips, {'2026-10-18|4'});
      expect(st.holidays, ['2026-11-01']);
      expect(st.done, {'x'});
    });

    test('validateState يرفض البيانات غير الصالحة', () {
      expect(Store.validateState('نص'), isNotNull);
      expect(Store.validateState({'x': 1}), isNotNull);
      expect(Store.validateState({'v': 99}), isNotNull);
      expect(Store.validateState({'app': 'smart_school_bell', 'v': 1}), isNotNull);
      expect(Store.validateState({'v': 1, 'offsets': []}), isNotNull);
      expect(Store.validateState(Store.I.toJson()), isNull);
    });
  });
}
