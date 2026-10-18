import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lesson_planner/utils/constants.dart';

// أدوات وعناصر واجهة مشتركة
// ---------- أدوات مساعدة للواجهة ----------
void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1300)));
}

void copyText(BuildContext context, String text, {String msg = 'تم النسخ'}) {
  Clipboard.setData(ClipboardData(text: text));
  toast(context, msg);
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
  var y = initial.year.clamp(2026, 2028).toInt();
  var m = initial.month;
  var d = initial.day;
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        final maxD = DateTime.utc(y, m + 1, 0).day;
        if (d > maxD) d = maxD;
        return AlertDialog(
          title: const Text('اختر التاريخ'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: d,
                items: [for (var i = 1; i <= maxD; i++) DropdownMenuItem<int>(value: i, child: Text('$i'))],
                onChanged: (v) => setS(() => d = v ?? d),
              ),
              DropdownButton<int>(
                value: m,
                items: [for (var i = 1; i <= 12; i++) DropdownMenuItem<int>(value: i, child: Text(kMonths[i - 1]))],
                onChanged: (v) => setS(() => m = v ?? m),
              ),
              DropdownButton<int>(
                value: y,
                items: [for (var i = 2026; i <= 2028; i++) DropdownMenuItem<int>(value: i, child: Text('$i'))],
                onChanged: (v) => setS(() => y = v ?? y),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, DateTime.utc(y, m, d)), child: const Text('موافق')),
          ],
        );
      });
    },
  );
}


class Sec extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg;
  final Color fg;
  final List<Widget> children;
  const Sec({super.key, required this.title, required this.icon, required this.bg, required this.fg, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 16))),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class WhiteCard extends StatelessWidget {
  final Widget child;
  const WhiteCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}

class FieldBox extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int minLines;
  final ValueChanged<String>? onChanged;
  final bool number;
  final bool copy;
  final String? hint;
  const FieldBox({super.key, required this.label, required this.ctrl, this.minLines = 2, this.onChanged, this.number = false, this.copy = true, this.hint});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54))),
            if (copy)
              InkWell(
                onTap: () => copyText(context, ctrl.text, msg: 'تم نسخ «$label»'),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy_rounded, size: 18, color: kPrimary)),
              ),
          ]),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            minLines: number ? 1 : minLines,
            maxLines: number ? 1 : null,
            keyboardType: number ? TextInputType.number : TextInputType.multiline,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const InfoTile({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ),
        InkWell(
          onTap: () => copyText(context, value, msg: 'تم نسخ «$label»'),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy_rounded, size: 18, color: kPrimary)),
        ),
      ]),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String ok = 'تأكيد'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}
