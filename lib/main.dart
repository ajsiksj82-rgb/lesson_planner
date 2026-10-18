import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Store.I.init();
  } catch (e) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تشغيل التطبيق:\n$e', textAlign: TextAlign.center)))),
      ),
    ));
    return;
  }
  runApp(const PlannerApp());
}