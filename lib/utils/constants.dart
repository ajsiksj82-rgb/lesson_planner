import 'package:flutter/material.dart';

// ---------- ثوابت ----------
const Color kPrimary = Color(0xFF0E7C66);
const Color kBg = Color(0xFFF2F7F6);
const List<String> kDayNames = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const List<String> kMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const List<String> kDomains = ['معرفي', 'مهاري', 'وجداني'];
const Map<String, List<String>> kLevels = {
  'معرفي': ['تذكر', 'فهم', 'تطبيق', 'تحليل', 'تركيب', 'تقويم'],
  'مهاري': ['تقليد', 'معالجة', 'إتقان', 'تكييف', 'ابتكار'],
  'وجداني': ['استقبال', 'استجابة', 'تقدير', 'تنظيم', 'تمييز'],
};
const Map<int, String> kGradeNames = {
  4: 'الرابع الأساسي',
  5: 'الخامس الأساسي',
  8: 'الثامن الأساسي',
  9: 'التاسع الأساسي',
  12: 'الثاني عشر',
};
const Map<int, Color> kGradeColors = {
  4: Color(0xFFFFE0B2),
  5: Color(0xFFB3E5FC),
  8: Color(0xFFE1BEE7),
  9: Color(0xFFC8E6C9),
  12: Color(0xFFFFF9C4),
};
const int kSessionsPerClass = 28; // 14 أسبوعاً × حصتان

// بداية الفصل حسب الخطة الفصلية (السبت 17 أكتوبر 2026)
final DateTime kTermStart = DateTime.utc(2026, 10, 17);
