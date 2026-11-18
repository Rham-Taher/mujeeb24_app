import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'common_ui_widgets.dart';

/// Interactive showcase and preview screen for Mujeeb24 Design System.
/// This screen is strictly for design auditing and widget testing; it is decoupled from production routes.
class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  State<DesignSystemPreviewScreen> createState() => _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState extends State<DesignSystemPreviewScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'سارة');
  final TextEditingController _textController = TextEditingController();
  String _selectedFilter = 'الكل';
  int _navIndex = 0;
  bool _isLoadingButton = false;

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.lightBlueBackground,
        appBar: const MujeebAppHeader(
          title: 'نظام تصميم Mujeeb24',
          subtitle: 'معاينة المكونات ونظام الألوان والخطوط',
        ),
        bottomNavigationBar: MujeebBottomNavigation(
          currentIndex: _navIndex,
          onTap: (index) => setState(() => _navIndex = index),
          items: const [
            MujeebBottomNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'الرئيسية',
            ),
            MujeebBottomNavItem(
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'المحادثات',
              badgeCount: 3,
            ),
            MujeebBottomNavItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_alt_rounded,
              label: 'العملاء',
            ),
            MujeebBottomNavItem(
              icon: Icons.trending_up_rounded,
              label: 'الفرص',
            ),
            MujeebBottomNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'الإعدادات',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // 1. Color Tokens Showcase
            _buildSection(
              title: '1. لوحة الألوان المعتمدة (Color Tokens)',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorChip('Primary Blue', AppColors.primaryBlue),
                  _buildColorChip('Dark Blue', AppColors.primaryBlueDark),
                  _buildColorChip('Background', AppColors.lightBlueBackground),
                  _buildColorChip('Card White', AppColors.cardWhite),
                  _buildColorChip('Heading Navy', AppColors.headingNavy),
                  _buildColorChip('Secondary Text', AppColors.secondaryText),
                  _buildColorChip('Success', AppColors.successGreen),
                  _buildColorChip('Warning', AppColors.warningAmber),
                  _buildColorChip('Error', AppColors.errorRed),
                  _buildColorChip('Disabled', AppColors.disabledText),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 2. Typography Hierarchy
            _buildSection(
              title: '2. التسلسل الطباعي (Typography Scale)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('عنوان الصفحة (Page Title) - 22px Bold', style: AppTypography.pageTitle),
                  SizedBox(height: 6),
                  Text('عنوان القسم (Section Title) - 18px Bold', style: AppTypography.sectionTitle),
                  SizedBox(height: 6),
                  Text('عنوان البطاقة (Card Title) - 14px SemiBold', style: AppTypography.cardTitle),
                  SizedBox(height: 6),
                  Text('نص المحتوى (Body) - 14px Regular: تجربة منصة المحادثات التجارية للتاجر.', style: AppTypography.body),
                  SizedBox(height: 6),
                  Text('نص ثانوي وتوضيحي (Secondary Text) - 12px Regular', style: AppTypography.secondaryText),
                  SizedBox(height: 6),
                  Text('نص التسمية المصغرة (Caption) - 11px Medium', style: AppTypography.caption),
                  SizedBox(height: 6),
                  Text('94.8% / 15,200 ر.س (Numeric Highlight) - 22px ExtraBold', style: AppTypography.numericHighlight),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 3. Statistics Cards (5-Grid overview)
            _buildSection(
              title: '3. بطاقات الإحصائيات (Metric Cards)',
              child: Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      value: '24',
                      label: 'محادثات نشطة',
                      color: AppColors.primaryBlue,
                      icon: Icons.chat_outlined,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MetricStatCard(
                      value: '3',
                      label: 'بانتظار الرد',
                      color: AppColors.warningAmber,
                      icon: Icons.hourglass_top_rounded,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MetricStatCard(
                      value: '18,400',
                      label: 'مبيعات اليوم (ر.س)',
                      color: AppColors.successGreen,
                      icon: Icons.attach_money_rounded,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 4. Avatars with Channel Badges & Presence
            _buildSection(
              title: '4. الصور الرمزية وقنوات التواصل (Avatars)',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  MujeebAvatar(
                    name: 'سارة أحمد',
                    channel: MujeebChannelType.whatsapp,
                    isOnline: true,
                  ),
                  MujeebAvatar(
                    name: 'محمد الخالدي',
                    channel: MujeebChannelType.instagram,
                    isOnline: true,
                  ),
                  MujeebAvatar(
                    name: 'عبد الله علي',
                    channel: MujeebChannelType.facebook,
                    isOnline: false,
                  ),
                  MujeebAvatar(
                    name: 'فاطمة حسن',
                    channel: MujeebChannelType.telegram,
                    isOnline: false,
                  ),
                  MujeebAvatar(
                    name: 'متجر الرياض',
                    channel: MujeebChannelType.none,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 5. Search Bar & Filter Chips
            _buildSection(
              title: '5. شريط البحث وشرائح الفلترة (Search & Filters)',
              child: Column(
                children: [
                  MujeebSearchBar(
                    controller: _searchController,
                    hintText: 'ابحث عن اسم، هاتف، أو رقم طلب...',
                    onClear: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilterChipGroup(
                    options: const ['الكل', 'واتساب', 'إنستغرام', 'غير مقروء', 'بانتظار التأكيد'],
                    selectedOption: _selectedFilter,
                    onSelected: (val) => setState(() => _selectedFilter = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 6. Action Buttons
            _buildSection(
              title: '6. الأزرار التفاعلية (Action Buttons)',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MujeebButton(
                    text: 'زر أساسي ممتلئ',
                    icon: Icons.send_rounded,
                    variant: MujeebButtonVariant.primary,
                    onPressed: () {},
                  ),
                  MujeebButton(
                    text: 'زر ثانوي خفيف',
                    icon: Icons.check_circle_outline,
                    variant: MujeebButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  MujeebButton(
                    text: 'زر تحذيري / إلغاء',
                    icon: Icons.delete_outline_rounded,
                    variant: MujeebButtonVariant.danger,
                    onPressed: () {},
                  ),
                  MujeebButton(
                    text: 'زر مفرغ بحدود',
                    icon: Icons.tune_rounded,
                    variant: MujeebButtonVariant.outline,
                    onPressed: () {},
                  ),
                  MujeebButton(
                    text: 'جارٍ الحفظ...',
                    isLoading: _isLoadingButton,
                    onPressed: () => setState(() => _isLoadingButton = !_isLoadingButton),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 7. Status Badges & Cards
            _buildSection(
              title: '7. شارات الحالات والبطاقات (Badges & Cards)',
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      StatusBadge(
                        label: 'مؤكدة',
                        color: AppColors.successGreen,
                        icon: Icons.check_circle_rounded,
                      ),
                      StatusBadge(
                        label: 'قيد المراجعة',
                        color: AppColors.warningAmber,
                        icon: Icons.hourglass_empty_rounded,
                      ),
                      StatusBadge(
                        label: 'ملغاة',
                        color: AppColors.errorRed,
                        icon: Icons.cancel_rounded,
                      ),
                      StatusBadge(
                        label: 'مسودة',
                        color: AppColors.primaryBlue,
                        icon: Icons.edit_note_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MujeebCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MujeebSectionHeader(
                          title: 'طلب جديد #ORD-9821',
                          count: 3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'تم إنشاء المسودة بواسطة ريم خالد - بانتظار تأكيد الدفع من العميل.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المبلغ الإجمالي:', style: AppTypography.secondaryText),
                            const Text('450 ر.س', style: AppTypography.numericHighlight),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 8. Form Fields
            _buildSection(
              title: '8. حقول الإدخال (Form Fields)',
              child: Column(
                children: [
                  MujeebTextField(
                    controller: _textController,
                    label: 'اسم المنشأة التجاري',
                    hint: 'أدخل الاسم الرسمي للمتجر',
                    prefixIcon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const MujeebTextField(
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 9. Feedback States (Empty, Loading, Error, Skeleton)
            _buildSection(
              title: '9. حالات التغذية الراجعة (Feedback States)',
              child: Column(
                children: [
                  const MujeebSkeletonCard(height: 56),
                  const SizedBox(height: AppSpacing.md),
                  MujeebCard(
                    child: MujeebEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'لا توجد عناصر حالياً',
                      message: 'ستظهر البيانات والتقارير بمجرد بدء استقبال الطلبات.',
                      actionText: 'إعادة التحديث',
                      onAction: () {},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MujeebCard(
                    child: MujeebErrorState(
                      title: 'تعذر الاتصال بالخادم',
                      message: 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
                      onRetry: () {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLightBlue),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildColorChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color == AppColors.cardWhite ? AppColors.headingNavy : color,
            ),
          ),
        ],
      ),
    );
  }
}
