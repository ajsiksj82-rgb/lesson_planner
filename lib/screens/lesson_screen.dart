import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/models/models.dart';
import 'package:lesson_planner/utils/constants.dart';
import 'package:lesson_planner/utils/date_utils.dart';
import 'package:lesson_planner/utils/lesson_text.dart';
import 'package:lesson_planner/widgets/common.dart';

// فتح تحضير حصة محددة
void openCtx(BuildContext context, Ctx c) {
  final st = Store.I;
  if (c.skipped) {
    toast(context, 'هذه الحصة موسومة بأنها لم تُعقد. استعدها من القائمة لعرض تحضيرها.');
    return;
  }
  if (!st.hasPlan(c.slot.g)) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPage(grade: c.slot.g, k: -1, dur: c.dur, ctx: c)));
    return;
  }
  if (!c.inRange) {
    toast(context, c.k < 0 ? 'هذه الحصة قبل بداية الخطة (راجع تاريخ البدء في الإعدادات).' : 'انتهت دروس الخطة الفصلية لهذه الشعبة.');
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPage(grade: c.slot.g, k: c.k, dur: c.dur, ctx: c)));
}

// ============================================================
//                        صفحة التحضير
// ============================================================
class LessonPage extends StatefulWidget {
  final int grade;
  final int k; // -1 = تحضير يدوي
  final int dur;
  final Ctx? ctx;
  const LessonPage({super.key, required this.grade, required this.k, required this.dur, this.ctx});
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late Lesson L;
  late int dur;
  String key = '';
  String rkey = '';
  TextEditingController topicC = TextEditingController();
  TextEditingController resC = TextEditingController();
  TextEditingController evC = TextEditingController();
  TextEditingController reflC = TextEditingController();
  TextEditingController ambC = TextEditingController();
  List<TextEditingController> goalC = [];
  List<List<TextEditingController>> itemC = [];

  bool get manual => widget.k < 0;

  @override
  void initState() {
    super.initState();
    dur = widget.dur;
    _load();
  }

  @override
  void dispose() {
    Store.I.save();
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    topicC.dispose();
    resC.dispose();
    evC.dispose();
    reflC.dispose();
    ambC.dispose();
    for (final c in goalC) {
      c.dispose();
    }
    for (final row in itemC) {
      for (final c in row) {
        c.dispose();
      }
    }
    goalC = [];
    itemC = [];
  }

  void _load() {
    final st = Store.I;
    if (manual) {
      key = 'M:${widget.ctx!.key}|${widget.ctx!.slot.cls}';
      if (st.edits.containsKey(key)) {
        L = Lesson.fromJson(Map<String, dynamic>.from(st.edits[key] as Map));
      } else {
        L = Lesson.blank();
      }
    } else {
      key = 'L:${widget.grade}:${widget.k}';
      L = st.lessonFor(widget.grade, widget.k);
    }
    rkey = widget.ctx == null ? '' : '${widget.ctx!.key}|${widget.ctx!.slot.cls}';
    _build();
  }

  void _build() {
    _disposeAll();
    final st = Store.I;
    topicC = TextEditingController(text: L.topic);
    resC = TextEditingController(text: L.res);
    evC = TextEditingController(text: L.ev);
    final r = st.refl[rkey] ?? <String, String>{};
    reflC = TextEditingController(text: r['r'] ?? '');
    ambC = TextEditingController(text: r['a'] ?? '');
    goalC = L.goals.map((g) => TextEditingController(text: g.t)).toList();
    final mins = L.minutes(dur);
    itemC = [
      for (var i = 0; i < L.items.length; i++)
        [
          TextEditingController(text: L.items[i].c),
          TextEditingController(text: L.items[i].t),
          TextEditingController(text: L.items[i].l),
          TextEditingController(text: '${mins[i]}'),
          TextEditingController(text: L.items[i].s),
        ],
    ];
  }

  void _syncTimes() {
    final mins = L.minutes(dur);
    for (var i = 0; i < itemC.length && i < mins.length; i++) {
      itemC[i][3].text = '${mins[i]}';
    }
  }

  void _save() {
    Store.I.edits[key] = L.toJson();
    Store.I.touchQuiet();
  }

  void _saveRefl() {
    if (rkey.isEmpty) return;
    Store.I.refl[rkey] = {'r': reflC.text, 'a': ambC.text};
    Store.I.touchQuiet();
  }

  void _restore() {
    Store.I.edits.remove(key);
    Store.I.touch();
    _load();
    setState(() {});
    toast(context, manual ? 'تم تفريغ التحضير' : 'تمت استعادة التحضير الأصلي');
  }

  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final ctx = widget.ctx;
    final g = widget.grade;
    final mins = L.minutes(dur);
    final sum = mins.fold<int>(0, (a, b) => a + b);
    final okSum = sum == dur;
    Map<String, dynamic>? wk;
    if (!manual) wk = st.weekInfo(g, widget.k ~/ 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحضير درس'),
        centerTitle: true,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'نسخ التحضير كاملاً',
            icon: const Icon(Icons.copy_all),
            onPressed: () => copyText(
              context,
              lessonText(L, dur, ctx: ctx, grade: g, refl1: reflC.text, refl2: ambC.text),
              msg: 'تم نسخ التحضير كاملاً',
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'restore') _restore();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'restore', child: Text(manual ? 'تفريغ التحضير' : 'استعادة الأصل')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
        children: [
          if (ctx == null && !manual)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const Text('مدة الحصة: '),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('35 د (سبت/أحد)'),
                  selected: dur == 35,
                  onSelected: (_) => setState(() {
                    dur = 35;
                    _syncTimes();
                  }),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('45 د'),
                  selected: dur == 45,
                  onSelected: (_) => setState(() {
                    dur = 45;
                    _syncTimes();
                  }),
                ),
              ]),
            ),
          // ----- المعلومات الأساسية -----
          Sec(
            title: 'المعلومات الأساسية',
            icon: Icons.info_outline,
            bg: const Color(0xFFE3F2FD),
            fg: const Color(0xFF1565C0),
            children: [
              if (ctx != null) ...[
                InfoTile(label: 'اليوم', value: kDayNames[dayIdx(ctx.date)]),
                InfoTile(label: 'التاريخ', value: fmt(ctx.date)),
                InfoTile(label: 'الحصة', value: '${ctx.slot.p}'),
                InfoTile(label: 'الشعبة', value: ctx.slot.sec),
              ],
              InfoTile(label: 'الصف', value: kGradeNames[g] ?? '$g'),
              const InfoTile(label: 'المادة', value: 'الحاسوب'),
              FieldBox(
                label: 'الموضوع / العنوان',
                ctrl: topicC,
                minLines: 1,
                onChanged: (v) {
                  L.topic = v;
                  _save();
                },
              ),
              if (L.sub.isNotEmpty)
                Text('${L.sub} — ${dur} دقيقة', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
              if (wk != null) ...[
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('من الخطة الفصلية — الأسبوع ${widget.k ~/ 2 + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الموضوع: ${wk['t']}\n'
                          'الهدف: ${(wk['pl'] as Map)['goal']}\n'
                          'الوسائل: ${(wk['pl'] as Map)['res']}\n'
                          'الاستراتيجيات: ${(wk['pl'] as Map)['str']}\n'
                          'التقويم: ${(wk['pl'] as Map)['ev']}',
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // ----- الأهداف -----
          Sec(
            title: 'الأهداف التعليمية',
            icon: Icons.flag,
            bg: const Color(0xFFFFF3E0),
            fg: const Color(0xFFE65100),
            children: [
              for (var i = 0; i < L.goals.length; i++) _goalCard(i),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    L.goals.add(Goal('', 'معرفي', 'تذكر'));
                    _save();
                    _build();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة هدف تعليمي جديد'),
                ),
              ),
            ],
          ),
          // ----- تنفيذ الدرس -----
          Sec(
            title: 'تنفيذ الدرس (عناصر المحتوى والأنشطة)',
            icon: Icons.menu_book,
            bg: const Color(0xFFE0F2F1),
            fg: const Color(0xFF00695C),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: okSum ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2), borderRadius: BorderRadius.circular(10)),
                  child: Text('مجموع الزمن: $sum من $dur دقيقة ${okSum ? '✓' : '(غير مطابق)'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ),
              for (var i = 0; i < L.items.length; i++) _itemCard(i),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    L.items.add(Item('', '', '', '', 1));
                    _save();
                    _build();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة محتوى جديد'),
                ),
              ),
            ],
          ),
          // ----- المصادر والتقويم -----
          Sec(
            title: 'مصادر التعلم والتقويم',
            icon: Icons.fact_check,
            bg: const Color(0xFFF3E5F5),
            fg: const Color(0xFF6A1B9A),
            children: [
              FieldBox(
                label: 'مصادر التعلم والوسائل المستخدمة',
                ctrl: resC,
                minLines: 1,
                onChanged: (v) {
                  L.res = v;
                  _save();
                },
              ),
              FieldBox(
                label: 'التقويم الختامي والواجب البيتي',
                ctrl: evC,
                minLines: 3,
                onChanged: (v) {
                  L.ev = v;
                  _save();
                },
              ),
              if (ctx != null) ...[
                FieldBox(label: 'التأمل الذاتي للمعلم (اختياري — يُستكمل بعد أداء الدرس)', ctrl: reflC, minLines: 3, onChanged: (_) => _saveRefl()),
                FieldBox(label: 'طموح تطوير الذات (اختياري — يُستكمل بعد أداء الدرس)', ctrl: ambC, minLines: 3, onChanged: (_) => _saveRefl()),
              ],
            ],
          ),
          if (ctx != null)
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text('تم إدخاله في تطبيق التحضير'),
                value: st.done.contains(ctx.key),
                onChanged: (v) {
                  if (v) {
                    st.done.add(ctx.key);
                  } else {
                    st.done.remove(ctx.key);
                  }
                  st.touch();
                  setState(() {});
                },
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => copyText(
              context,
              lessonText(L, dur, ctx: ctx, grade: g, refl1: reflC.text, refl2: ambC.text),
              msg: 'تم نسخ التحضير كاملاً',
            ),
            icon: const Icon(Icons.copy_all),
            label: const Text('نسخ التحضير كاملاً'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restore,
            icon: const Icon(Icons.restore),
            label: Text(manual ? 'تفريغ التحضير' : 'استعادة التحضير الأصلي'),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(int i) {
    final gl = L.goals[i];
    final dom = kLevels.containsKey(gl.d) ? gl.d : 'معرفي';
    final levels = kLevels[dom] ?? kLevels['معرفي']!;
    if (!levels.contains(gl.l)) gl.l = levels.first;
    gl.d = dom;
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: const Color(0xFFFFE0B2), child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)))),
          const Spacer(),
          if (L.goals.length > 1)
            IconButton(
              onPressed: () {
                L.goals.removeAt(i);
                _save();
                _build();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ]),
        FieldBox(
          label: 'الهدف التعليمي',
          ctrl: goalC[i],
          onChanged: (v) {
            gl.t = v;
            _save();
          },
        ),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('المجال', style: TextStyle(fontSize: 12, color: Colors.black54)),
              DropdownButton<String>(
                isExpanded: true,
                value: dom,
                items: [for (final d in kDomains) DropdownMenuItem<String>(value: d, child: Text(d))],
                onChanged: (v) {
                  if (v == null) return;
                  gl.d = v;
                  gl.l = (kLevels[v] ?? kLevels['معرفي']!).first;
                  _save();
                  setState(() {});
                },
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('المستوى', style: TextStyle(fontSize: 12, color: Colors.black54)),
              DropdownButton<String>(
                isExpanded: true,
                value: gl.l,
                items: [for (final l in levels) DropdownMenuItem<String>(value: l, child: Text(l))],
                onChanged: (v) {
                  if (v == null) return;
                  gl.l = v;
                  _save();
                  setState(() {});
                },
              ),
            ]),
          ),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => copyText(context, '${gl.t}', msg: 'تم نسخ نص الهدف'),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text('نسخ الهدف (${gl.d} – ${gl.l})'),
          ),
        ),
      ]),
    );
  }

  Widget _itemCard(int i) {
    final it = L.items[i];
    final c = itemC[i];
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: const Color(0xFFB2DFDB), child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C)))),
          const SizedBox(width: 8),
          const Text('عنصر محتوى', style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
          const Spacer(),
          if (L.items.length > 1)
            IconButton(
              onPressed: () {
                L.items.removeAt(i);
                _save();
                _build();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ]),
        FieldBox(
          label: 'المحتوى / المادة العلمية',
          ctrl: c[0],
          minLines: 3,
          onChanged: (v) {
            it.c = v;
            _save();
          },
        ),
        FieldBox(
          label: 'نشاط المعلم',
          ctrl: c[1],
          onChanged: (v) {
            it.t = v;
            _save();
          },
        ),
        FieldBox(
          label: 'نشاط المتعلم',
          ctrl: c[2],
          onChanged: (v) {
            it.l = v;
            _save();
          },
        ),
        FieldBox(
          label: 'الزمن (بالدقائق)',
          ctrl: c[3],
          number: true,
          onChanged: (v) {
            final n = int.tryParse(v);
            if (dur == 35) {
              it.m35 = n;
            } else {
              it.m45 = n;
            }
            _save();
            setState(() {});
          },
        ),
        FieldBox(
          label: 'استراتيجيات التدريس',
          ctrl: c[4],
          minLines: 1,
          onChanged: (v) {
            it.s = v;
            _save();
          },
        ),
      ]),
    );
  }
}

