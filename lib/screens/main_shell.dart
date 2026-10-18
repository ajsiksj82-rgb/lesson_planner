import 'package:flutter/material.dart';

import 'package:lesson_planner/app/app_state.dart';
import 'package:lesson_planner/screens/library_screen.dart';
import 'package:lesson_planner/screens/settings_screen.dart';
import 'package:lesson_planner/screens/today_screen.dart';
import 'package:lesson_planner/screens/week_screen.dart';

// ============================================================
//                       الهيكل الرئيسي
// ============================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Store.I.onboarded) _askStart();
    });
  }

  Future<void> _askStart() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('مرحباً بك'),
        content: const Text('هل أُعطيت حصص يوم السبت 17 أكتوبر 2026 (أول يوم في الفصل)؟\n\nيحدد ذلك الدرس الذي تبدأ به كل شعبة. ويمكنك تغيير التاريخ لاحقاً من الإعدادات.'),
        actions: [
          TextButton(
            onPressed: () {
              Store.I.start = '2026-10-18';
              Store.I.onboarded = true;
              Store.I.touch();
              Navigator.pop(ctx);
            },
            child: const Text('لا، أبدأ من الأحد 18 أكتوبر'),
          ),
          ElevatedButton(
            onPressed: () {
              Store.I.start = '2026-10-17';
              Store.I.onboarded = true;
              Store.I.touch();
              Navigator.pop(ctx);
            },
            child: const Text('نعم، من السبت 17 أكتوبر'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Store.I,
      builder: (context, _) {
        return Scaffold(
          // ملاحظة: بدون const حتى تُعاد بناء الصفحات عند تغير بيانات المخزن
          body: IndexedStack(index: tab, children: [TodayPage(), WeekPage(), LibraryPage(), SettingsPage()]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'اليوم'),
              NavigationDestination(icon: Icon(Icons.calendar_view_week_outlined), selectedIcon: Icon(Icons.calendar_view_week), label: 'الجدول'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'الدروس'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
            ],
          ),
        );
      },
    );
  }
}
