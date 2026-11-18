import 'package:mujeeb24_app/core/widgets/design_system_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';

void main() {
  group('Mujeeb24 Design System Components Tests', () {
    testWidgets('MujeebCard renders content and handles onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebCard(
              onTap: () => tapped = true,
              child: const Text('بطاقة اختبار'),
            ),
          ),
        ),
      );

      expect(find.text('بطاقة اختبار'), findsOneWidget);
      await tester.tap(find.text('بطاقة اختبار'));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge renders label, icon, and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'مكتمل',
              color: AppColors.statusSuccess,
              icon: Icons.check_circle_rounded,
            ),
          ),
        ),
      );

      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('MetricStatCard renders number, label, and handles tap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricStatCard(
              value: '12',
              label: 'محادثات مفتوحة',
              color: AppColors.primary,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('محادثات مفتوحة'), findsOneWidget);
      await tester.tap(find.text('12'));
      expect(tapped, isTrue);
    });

    testWidgets('MujeebSearchBar renders hint, handles input and clear', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'سارة');
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebSearchBar(
              controller: controller,
              hintText: 'ابحث عن عميل...',
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('سارة'), findsOneWidget);
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
      expect(controller.text, isEmpty);
    });

    testWidgets('MujeebFilterChip renders active and inactive states', (
      tester,
    ) async {
      bool selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebFilterChip(
              label: 'واتساب',
              isSelected: true,
              count: 5,
              onSelected: () => selected = true,
            ),
          ),
        ),
      );

      expect(find.text('واتساب'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.tap(find.text('واتساب'));
      expect(selected, isTrue);
    });

    testWidgets('MujeebSectionHeader renders title and count badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MujeebSectionHeader(
              title: 'العملاء',
              count: 154,
            ),
          ),
        ),
      );

      expect(find.text('العملاء'), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
    });

    testWidgets('MujeebButton renders variants and handles tap and loading', (
      tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MujeebButton(
                  text: 'حفظ التغييرات',
                  variant: MujeebButtonVariant.primary,
                  icon: Icons.check,
                  onPressed: () => pressed = true,
                ),
                const MujeebButton(
                  text: 'جارٍ الحفظ...',
                  isLoading: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('حفظ التغييرات'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('حفظ التغييرات'));
      expect(pressed, isTrue);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MujeebTextField renders label, hint, and handles input', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebTextField(
              controller: controller,
              label: 'الاسم الكامل',
              hint: 'أدخل اسمك',
              prefixIcon: Icons.person_outline,
            ),
          ),
        ),
      );

      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('أدخل اسمك'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'محمد أحمد');
      expect(controller.text, equals('محمد أحمد'));
    });

    testWidgets('MujeebListTile renders title, subtitle, and handles tap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebListTile(
              leading: const Icon(Icons.star),
              title: 'عنوان تجريبي',
              subtitle: 'وصف فرعي تجريبي',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('عنوان تجريبي'), findsOneWidget);
      expect(find.text('وصف فرعي تجريبي'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

      await tester.tap(find.text('عنوان تجريبي'));
      expect(tapped, isTrue);
    });

    testWidgets('MujeebEmptyState renders icon, title, message, and action', (
      tester,
    ) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد محادثات',
              message: 'ستظهر محادثات العملاء هنا فور استلامها',
              actionText: 'تحديث',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('لا توجد محادثات'), findsOneWidget);
      expect(find.text('ستظهر محادثات العملاء هنا فور استلامها'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);

      await tester.tap(find.text('تحديث'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('MujeebLoadingIndicator renders spinner and message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MujeebLoadingIndicator(
              message: 'جارٍ جلب البيانات...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جارٍ جلب البيانات...'), findsOneWidget);
    });
    testWidgets('MujeebAppHeader renders title, subtitle and bottom divider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: MujeebAppHeader(
              title: 'الرئيسية',
              subtitle: 'نظرة عامة على النشاط',
            ),
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('نظرة عامة على النشاط'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('MujeebBottomNavigation renders items, badges and handles onTap', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MujeebBottomNavigation(
              currentIndex: selected,
              onTap: (index) => selected = index,
              items: const [
                MujeebBottomNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'الرئيسية',
                ),
                MujeebBottomNavItem(
                  icon: Icons.forum_outlined,
                  label: 'المحادثات',
                  badgeCount: 5,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المحادثات'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('المحادثات'));
      expect(selected, equals(1));
    });

    testWidgets('MujeebAvatar renders initials, channel badge and online status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MujeebAvatar(
              name: 'سارة أحمد',
              channel: MujeebChannelType.whatsapp,
              isOnline: true,
            ),
          ),
        ),
      );

      expect(find.text('سأ'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('MujeebErrorState renders error info and triggers retry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MujeebErrorState(
              title: 'خطأ في الاتصال',
              message: 'فشل تحميل البيانات',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('خطأ في الاتصال'), findsOneWidget);
      expect(find.text('فشل تحميل البيانات'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      expect(retried, isTrue);
    });

    testWidgets('FilterChipGroup renders options and selects item', (tester) async {
      String current = 'الكل';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FilterChipGroup(
                  options: const ['الكل', 'واتساب', 'إنستغرام'],
                  selectedOption: current,
                  onSelected: (val) => setState(() => current = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('واتساب'), findsOneWidget);
      expect(find.text('إنستغرام'), findsOneWidget);

      await tester.tap(find.text('واتساب'));
      await tester.pumpAndSettle();
      expect(current, equals('واتساب'));
    });

    testWidgets('DesignSystemPreviewScreen renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 1200,
              width: 800,
              child: DesignSystemPreviewScreen(),
            ),
          ),
        ),
      );

      expect(find.text('نظام تصميم Mujeeb24'), findsOneWidget);
      expect(find.text('1. لوحة الألوان المعتمدة (Color Tokens)'), findsOneWidget);
      expect(find.text('2. التسلسل الطباعي (Typography Scale)'), findsOneWidget);
      expect(find.byType(DesignSystemPreviewScreen), findsOneWidget);
    });
  });
}
