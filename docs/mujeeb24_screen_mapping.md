# Mujeeb24 — خريطة الشاشات والمطابقة المرجعية (Screen Mapping & Reference Analysis)
## المرحلة 0: التحليل المرجعي والهيكلي قبل التنفيذ (PHASE 0)

> **تاريخ التقرير:** 1 نوفمبر 2026  
> **حالة الوثيقة:** معتمدة للبدء في المراحل التنفيذية المتسلسلة  
> **الهدف:** توثيق جميع الشاشات الفعلية داخل كود Flutter الحالي، وتحديد مسار الوصول إليها، ومطابقتها بلوحة المرجع البصري ونظام تصميم Stitch، مع حصر العمليات المنطقية المحمية، والاختبارات المرتبطة، وترتيب مراحل التنفيذ دون أي تغيير في المنطق البرمجي.

---

## 1. ملخص خط الأساس لحالة المستودع (Repository Baseline)

- **فرع العمل:** `feature/design`
- **حالة Git Status:** توجد تعديلات سابقة في شجرة العمل (31 ملفاً معدلاً + مكونات الواجهة المشتركة `lib/core/widgets/common_ui_widgets.dart` واختباراتها)، تم فحصها والمحافظة عليها دون استخدام أي أمر مدمر (`reset` أو `checkout` أو `restore`).
- **نتائج الاختبارات (`flutter test`):** **280 / 280 اختباراً ناجحاً بنسبة 100%**.
- **التحليل الساكن (`flutter analyze`):** **0 أخطاء (0 Errors)**، **0 تحذيرات (0 Warnings)**.

---

## 2. جدول المطابقة الشامل بين شاشات التطبيق والمرجع البصري

| الرقم | اسم الشاشة / المكون في Flutter | مسار الملف الفعلي | طريقة ومسار الوصول (Route / Navigation) | الشاشة المقابلة في المرجع البصري (Stitch / Board) | الاختلافات أو الملاحظات الوظيفية إن وجدت |
|:---:|:---|:---|:---|:---|:---|
| **0** | **شاشة بدء التشغيل والتحقق (Splash/Loading)** | `lib/app/app.dart` (`_restoreSessionAtStartup`) | شاشة تلقائية عند فتح التطبيق أثناء فحص الجلسة | شاشة Splash / التحميل في نظام التصميم | مدمجة في دورة حياة `MujeebApp` عبر `MaterialApp` مبسط ومؤشر تحميل |
| **1** | **تسجيل الدخول (Login)** | `lib/features/auth/presentation/login_screen.dart` | `AppRoute.login` في `lib/app/app.dart` | `stitch_mujeeb_24_mobile_design_system/login` (`screen.png` & `code.html`) | مطابقة تامة؛ تحتوي على حقول البريد/الهاتف وكلمة المرور وزر الدخول ورابط الدعوة |
| **2** | **قبول الدعوة (Invitation)** | `lib/features/auth/presentation/invitation_screen.dart` | `AppRoute.invitation` أو عبر رابط Deep Link من `DeepLinkService` | نظام بطاقات الإدخال في `login/` و `_1/` | مخصصة للموظفين المدعوين لإدخال الاسم وتعيين كلمة المرور وقبول الانضمام |
| **3** | **اختيار المنشأة (Business Selection)** | `lib/features/workspace/presentation/business_selection_screen.dart` | `AppRoute.businessSelection` (عند امتلاك المستخدم أكثر من منشأة) | شريط تبديل المنشأة العلوي في `home_dashboard` | قائمة بطاقات للمنشآت المتاحة مع شارات الأدوار والصلاحيات وزر اختيار |
| **4** | **واجهة مساحة العمل البديلة (Workspace)** | `lib/features/workspace/presentation/workspace_screen.dart` | `AppRoute.workspace` (في الحالات الاحتياطية خارج القشرة الرئيسية) | بطاقات الهوية التنظيمية في `home_dashboard` | تعرض تفاصيل المنشأة المحددة ورقمها وصلاحيات الدور |
| **5** | **القشرة الرئيسية للتاجر (Merchant Home Shell)** | `lib/features/merchant/presentation/merchant_home_screen.dart` | `AppRoute.workspace` الشاشة الأساسية بعد تسجيل الدخول | الهيكل العام وإطار التنقل السفلي (Bottom Navigation) في `DESIGN.md` | شريط تنقل سفلي يضم 5 تبويبات رئيسية + شريط علوي (AppBar) مع قائمة أدوات |
| **6** | **لوحة التحكم الرئيسية (Home Dashboard Tab)** | `lib/features/merchant/presentation/dashboard_tab.dart` | التبويب الأول (فهرس 0) داخل `MerchantHomeScreen` | `stitch_mujeeb_24_mobile_design_system/home_dashboard` | بطاقات المؤشرات الخمسة، الإجراءات السريعة، بانر مراجعة الطلبات، النشاط الأخير |
| **7** | **صندوق الوارد (Inbox Tab)** | `lib/features/merchant/presentation/inbox_tab.dart` | التبويب الثاني (فهرس 1) داخل `MerchantHomeScreen` | `stitch_mujeeb_24_mobile_design_system/inbox` | شريط البحث، شرائح التصفية (الكل، غير مقروء، القنوات)، بطاقات المحادثات مع SLA |
| **8** | **تفاصيل المحادثة (Conversation Detail)** | `lib/features/merchant/presentation/conversation_detail_screen.dart` | النقر على أي محادثة في `InboxTab` عبر `Navigator.push` | `stitch_mujeeb_24_mobile_design_system/_1` و `_2` | رأس المحادثة بمعلومات العميل، شريط سياق العميل المصغر، فقاعات الرسائل، الملاحظات الداخلية، شريط الرد |
| **9** | **دليل العملاء (Customers Tab)** | `lib/features/crm/presentation/customers_tab.dart` | التبويب الثالث (فهرس 2) في `MerchantHomeScreen` | `stitch_mujeeb_24_mobile_design_system/customers_directory` | تصفح العملاء، البحث السريع، فلاتر القنوات والوسوم، بطاقات بيانات الشراء |
| **10** | **تفاصيل وملف العميل (Customer Detail)** | `lib/features/crm/presentation/customer_detail_screen.dart` | النقر على عميل في `CustomersTab` عبر `Navigator.push` | `stitch_mujeeb_24_mobile_design_system/customer_merge` | عرض بيانات العميل وسجل الطلبات والمحادثات وزر تدفق دمج العملاء المكررين |
| **11** | **نموذج إنشاء/تعديل العميل (Customer Form)** | `lib/features/crm/presentation/customer_form_screen.dart` | زر الإضافة في `CustomersTab` أو زر التعديل في `CustomerDetailScreen` | حقول النماذج الموحدة في نظام تصميم `customers_directory/` | حقول الاسم ورقم الهاتف والبريد والملاحظات مع قواعد التحقق |
| **12** | **مسار الفرص البيعية (Leads Pipeline Tab)** | `lib/features/crm/presentation/leads_tab.dart` | التبويب الرابع (فهرس 3) في `MerchantHomeScreen` | `stitch_mujeeb_24_mobile_design_system/leads_pipeline` | مراحل الفرص (جديد، مؤهل، تفاوض، فوز/خسارة)، بطاقات الدرجات (Hot/Warm/Cold) |
| **13** | **تفاصيل الفرصة البيعية (Lead Detail)** | `lib/features/crm/presentation/lead_detail_screen.dart` | النقر على فرصة في `LeadsTab` عبر `Navigator.push` | `stitch_mujeeb_24_mobile_design_system/lead_details` و `mark_as_lost` | بيانات الفرصة، محدد المراحل التفاعلي، زر التأهيل، نافذة تسجيل سبب الخسارة |
| **14** | **نموذج الفرصة البيعية (Lead Form)** | `lib/features/crm/presentation/lead_form_screen.dart` | زر إضافة فرصة في `LeadsTab` أو التعديل من `LeadDetailScreen` | حقول النماذج الموحدة في `lead_details/` | إدخال القيمة المتوقعة وتعيين العضو وتحديد المرحلة ومصدر القناة |
| **15** | **قائمة المعاملات والطلبات (Transactions)** | `lib/features/transactions/presentation/transactions_screen.dart` | من لوحة التحكم أو القائمة العلوية أو بانر المراجعات | `stitch_mujeeb_24_mobile_design_system/sales_transactions` | بطاقات الطلبات مع رقم المعاملة المعزول اتجاهياً، الإجمالي، الحالة، الفلاتر |
| **16** | **تفاصيل المعاملة (Transaction Detail)** | `lib/features/transactions/presentation/transaction_detail_screen.dart` | النقر على معاملة في `TransactionsScreen` | تدفق تفاصيل المعاملة والاعتماد في `sales_transactions/` | ملخص الطلب، جدول البنود، كبسولات الحالة، حوارات الاعتماد/الرفض/التأكيد/الإلغاء |
| **17** | **نموذج مسودة المعاملة (Transaction Draft Form)** | `lib/features/transactions/presentation/transaction_draft_form_screen.dart` | زر إضافة معاملة من `TransactionsScreen` أو إجراءات لوحة التحكم | تدفق إنشاء المسودة في `sales_transactions/` | اختيار العميل وإضافة بنود من الكتالوج والحساب التلقائي للإجماليات |
| **18** | **قوائم الكتالوج (Catalogs)** | `lib/features/catalog/presentation/catalogs_screen.dart` | زر الكتالوج في شريط التطبيق العلوي أو من لوحة التحكم | شاشات الكتالوج والمنتجات في المرجع البصري | عرض الكتالوجات المتاحة للمنشأة مع أزرار الإضافة والتعديل |
| **19** | **عناصر الكتالوج والمنتجات (Catalog Items)** | `lib/features/catalog/presentation/catalog_items_screen.dart` | فتح أي كتالوج من `CatalogsScreen` | قائمة المنتجات في لوحة المرجع البصري | بطاقات المنتجات مع الصورة وحالة التوفر والسعر بالريال السعودي |
| **20** | **تفاصيل المنتج (Catalog Item Detail)** | `lib/features/catalog/presentation/catalog_item_detail_screen.dart` | النقر على منتج في `CatalogItemsScreen` | تفاصيل المنتج في لوحة المرجع البصري | عرض المتغيرات (Variants)، العروض الترويجية، وجداول السمات والمواصفات |
| **21** | **نموذج المنتج (Catalog Item Form)** | `lib/features/catalog/presentation/catalog_item_form_screen.dart` | زر إضافة منتج أو تعديل منتج قائم | نماذج إدخال المنتجات في المرجع البصري | حقول الاسم والوصف والسعر والرمز والمواصفات المتوافقة مع CLDR |
| **22** | **مخططات السمات (Attribute Schemas)** | `lib/features/catalog/presentation/attribute_schemas_screen.dart` | من شاشة الكتالوج لإدارة المواصفات | مواصفات المنتجات في المرجع البصري | إضافة وتعديل أنواع السمات (نصي، رقمي، اختيار متعدد) للمنتجات |
| **23** | **قنوات الاتصال المربوطة (Channels)** | `lib/features/channels/presentation/channels_screen.dart` | من لوحة التحكم أو القائمة العلوية للتاجر | بطاقات القنوات وحالات الاتصال في المرجع البصري | إدارة ربط قنوات واتساب وإنستغرام وفيسبوك، التفعيل، وتأكيد الحذف الحذر |
| **24** | **الردود السريعة الجاهزة (Canned Replies)** | `lib/features/channels/presentation/canned_replies_screen.dart` | من شاشة القنوات أو إجراءات لوحة التحكم | شاشة الردود السريعة المساعدة في `_2/` | إضافة واختصار وتعديل قوالب الردود المتكررة للمحادثات |
| **25** | **قواعد الأتمتة (Automation Rules)** | `lib/features/channels/presentation/automation_rules_screen.dart` | من شاشة القنوات | قواعد التوجيه في المرجع البصري | قواعد التعيين والتصعيد التلقائي للمحادثات |
| **26** | **قرارات الذكاء الاصطناعي (AI Decisions)** | `lib/features/channels/presentation/ai_decisions_screen.dart` | من شاشة القنوات أو الإعدادات | بطاقات مقترحات الذكاء الاصطناعي الموثقة في `DESIGN.md` | تدقيق المقترحات، مستوى الثقة، وطلب التدخل البشري (Request Human Review) |
| **27** | **إعدادات المنشأة (Business Settings Tab)** | `lib/features/merchant/presentation/business_settings_tab.dart` | التبويب الخامس (فهرس 4) في `MerchantHomeScreen` | شاشة الإعدادات في نظام التصميم | ساعات العمل، سياسات الرد، تغيير اللغة، التنقل للفريق والاشتراك والمنصة |
| **28** | **فريق العمل وإدارة الصلاحيات (Team)** | `lib/features/team/presentation/team_screen.dart` | من إعدادات المنشأة أو القائمة العلوية | شاشة الفريق وإدارة الأعضاء في المرجع البصري | قائمة الأعضاء، الأدوار، إرسال الدعوات بالبريد، وإلغاء/تعديل الوصول |
| **29** | **سجل التدقيق الزمني (Audit Logs)** | `lib/features/team/presentation/audit_logs_screen.dart` | من إعدادات المنشأة أو القائمة العلوية | سجل الأحداث والرقابة في المرجع البصري | استعراض الأحداث الأمنية والعمليات الحساسة مع طوابع زمنية دقيقة |
| **30** | **الاشتراك واستهلاك الباقة (Subscription)** | `lib/features/subscription/presentation/subscription_screen.dart` | من إعدادات المنشأة أو القائمة العلوية | بطاقات استهلاك الباقات في نظام التصميم | كروت الحصص المستهلكة (رسائل، قنوات، أعضاء) وزر الترقية وسجل الفواتير |
| **31** | **خطط وباقات الاشتراك (Subscription Plans)** | `lib/features/subscription/presentation/subscription_plans_screen.dart` | زر الترقية من `SubscriptionScreen` أو الإعدادات | بطاقات التسعير والترقية في نظام التصميم | مقارنة الباقات (أساسية، نمو، احترافية) ونافذة التحويل البنكي اليدوي |
| **32** | **مركز المنصة للمشرفين (Platform Hub)** | `lib/features/platform/presentation/platform_hub_screen.dart` | يظهر فقط في القائمة العلوية والإعدادات إذا كان المستخدم مشرف منصة | شاشة إدارة المنصة Platform Management في المرجع البصري | استعراض جميع المنشآت والمستأجرين وتعديل الباقات العامة على مستوى الخادم |

---

## 3. العناصر البصرية المطلوب تنفيذها لكل مجموعة شاشات

### 3.1 الهوية العامة وعناصر السطح (Global Tokens)
- **الألوان الأساسية:** اعتماد التدرج الأزرق الكهربي المعتمد في Mujeeb24 (`#087FF5`) مع الأزرق الكحلي العميق (`#123B8F`) للعناوين الرئيسية.
- **الخلفيات:** نقاء السطح باللون الأبيض (`#FFFFFF`) والحاويات الثانوية بـ (`#F8FAFC`) و (`#F1F5F9`).
- **الحدود:** حدود دقيقة بلون أزرق رمادي فاتح جداً (`#E2E8F0`) بسماكة 0.8px إلى 1px.
- **الظلال:** إزالة كافة الظلال العميقة المعتمة واستبدالها بظلال ناعمة جداً `0 1px 3px rgba(15, 23, 42, 0.04)`.
- **نصف القطر (Radius):** 10px إلى 14px للبطاقات وحقول الإدخال، وكبسولة كاملة (`9999px`) للشارات وشرائح التصفية.

### 3.2 المحادثات وصندوق الوارد (Conversations & Inbox)
- شارات القنوات الرسمية (WhatsApp الأخضر `#25D366`، Instagram الوردي `#E1306C`، Facebook الأزرق `#1877F2`) مثبتة أسفل صورة العميل الدائرية.
- فقاعات الرسائل غير المتماثلة (Inbound بـ `#F1F5F9` بزاوية علوية 16px وزاوية سفلية 4px، Outbound بـ `#087FF5` بزاوية علوية 16px وزاوية سفلية 4px).
- بطاقات الملاحظات الداخلية باللون الكهرماني التحذيري `#FFFBEB` مع أيقونة القفل ووسم "داخلي فقط".
- بطاقات مقترحات الذكاء الاصطناعي مع إطار منقط باللون البنفسجي `#7C3AED` وأزرار الإجراء السريع.

### 3.3 لوحة التحكم والعمليات التجارية (Dashboard, CRM & Transactions)
- شبكة العدادات الخمسة في لوحة التحكم بخلفيات بيضاء ناصعة وأرقام عريضة.
- بطاقات الطلبات والعملاء المحتملين مع تصنيف الدرجات بألوان دلالية واضحة (Hot أحمر/برتقالي، Warm أصفر، Cold أزرق رمادي).
- عزل ثنائي الاتجاه (BiDi Isolation) لجميع أرقام الهواتف وأكواد الطلبات والعملات بالريال السعودي.

---

## 4. المكونات المشتركة المستخرجة (Shared UI Components)

تتمركز جميع مكونات العرض المشتركة في:
[`lib/core/widgets/common_ui_widgets.dart`](file:///d:/mujeeb24-app/lib/core/widgets/common_ui_widgets.dart)

1. **`MujeebCard`:** بطاقة بيضاء مرتفعة بحدود رفيعة وظل ناعم تدعم التفاعل اللمسي.
2. **`StatusBadge`:** كبسولة حالة دلالية بخلفية شفافة خفيفة وحدود متناسقة للأوامر والفرص والمحادثات.
3. **`MetricStatCard`:** بطاقة مقاييس إحصائية تعرض القيمة الرقمية العريضة والتسمية التوضيحية والأيقونة.
4. **`MujeebSearchBar`:** حقل بحث مدمج يدعم زر المسح السريع ومطابق لمرجع صندوق الوارد.
5. **`MujeebFilterChip`:** شريحة تصفية تفاعلية متحركة ناعمة تعرض التسمية وعداد النتائج اختياريًا.
6. **`MujeebSectionHeader`:** ترويسة أقسام تضم العنوان وشارة العداد الإجمالي وزر إجراء اختياري.
7. **`MujeebButton`:** زر تفاعلي متعدد المتغيرات (أساسي، ثانوي، تحذيري، مفرغ) مع دعم حالة التحميل المدمجة.
8. **`MujeebTextField`:** حقل إدخال موحد بنصوص مساعدة وتلميحات وإطارات متفاعلة مع التركيز والخطأ.
9. **`MujeebListTile`:** عنصر قائمة موحد يدعم الأيقونات والعناوين والوسوم التفاعلية.
10. **`MujeebEmptyState`:** حالة فارغة أنيقة دائرية عند خلو القوائم من البيانات.
11. **`MujeebLoadingIndicator`:** مؤشر تحميل أزرق مركزي أنيق متناسق مع مقاسات الشاشات.

---

## 5. العمليات والمنطق البرمجي المحمي (Strict Business Logic Freeze)

يُحظر منعاً باتاً تعديل أي مما يلي أثناء أي مرحلة تنفيذية:
1. **واجهات الـ API:** جميع عناوين Endpoints، طرق الـ HTTP، حمولات الطلبات (Payloads)، وترميز الـ JSON في `lib/core/api/api_client.dart` وجميع الـ Repositories.
2. **مزودات البيانات وإدارة الحالة (Providers):** دوال جلب وتحديث وتصفية البيانات، ومواعيد إطلاق `notifyListeners` ودورة حياة `ChangeNotifier`.
3. **النماذج ومستودعات البيانات (Models & Repositories):** سلامة كائنات `auth_models.dart`, `merchant_models.dart`, `crm_models.dart`, `transaction_models.dart`, `catalog_models.dart`, `team_audit_models.dart`, `platform_models.dart`, `subscription_models.dart`.
4. **الحسابات المالية وقواعد الضرائب:** معادلات احتساب إجمالي الطلبات والخصومات والضرائب بالريال السعودي في مسودات وتفاصيل المعاملات.
5. **الأمان وصلاحيات المستخدمين:** حماية صلاحيات الوصول للأدوار (مثل حصر شاشة `PlatformHubScreen` على المشرف العام).
6. **إدارة الجلسات والمصادقة والتنقل:** دورة حياة الـ Refresh Cookie، روابط الدعوات العميقة (Deep Links)، ومعاملات المسارات (Route Arguments).

---

## 6. مصفوفة الاختبارات المرتبطة بكل شاشة (Test Matrix)

| مجموعة الشاشات | ملف الاختبار المرتبط | ما يتم التحقق منه |
|:---|:---|:---|
| **المصادقة والدخول** | `test/login_screen_test.dart` & `test/auth_session_lifecycle_test.dart` | التحقق من صحة المدخلات، تسجيل الدخول الناجح، رسائل الخطأ 401، دوران توكن التحديث |
| **الدعوات والروابط** | `test/invitation_deep_link_test.dart` & `test/team_invitation_state_ux_test.dart` | استقبال التوكن عبر Deep Link، ملء البيانات، والانضمام للمنشأة |
| **لوحة التحكم وصندوق الوارد** | `test/merchant_widgets_test.dart` & `test/merchant_filters_test.dart` | ظهور البطاقات الإحصائية، فلترة المحادثات، عدادات غير المقروء، التنقل للتفاصيل |
| **المحادثات والرسائل** | `test/message_ordering_and_backlog_test.dart` & `test/mobile_merchant_ux_regression_test.dart` | ترتيب الرسائل الزمني، إرسال الردود، الملاحظات الداخلية، شارات SLA |
| **إدارة العملاء والفرص (CRM)** | `test/crm_widgets_test.dart` & `test/crm_models_and_repository_test.dart` | عرض قائمة العملاء، التصفية بالوسوم، مراحل الفرص، حوار تسجيل الخسارة |
| **المعاملات والطلبات** | `test/transaction_widgets_test.dart` & `test/transaction_models_and_repository_test.dart` | إنشاء المسودة، إضافة بنود، فلاتر الحالات، دورة حياة الاعتماد والرفض والتأكيد |
| **الكتالوج والمنتجات** | `test/catalog_widgets_test.dart` & `test/catalog_arabic_parity_test.dart` | عرض المنتجات، إدخال المواصفات، تسعير العملات بالريال، عدم حدوث Overflow عند 320px |
| **القنوات والأتمتة والذكاء الاصطناعي** | `test/channel_automation_widgets_test.dart` | تفعيل/إلغاء القنوات، قوالب الردود السريعة، مراجعة قرارات الذكاء الاصطناعي |
| **الفريق والتدقيق** | `test/team_audit_widgets_test.dart` | قائمة الأعضاء، دعوة موظف، صلاحيات الأدوار، سجل الأحداث والرقابة |
| **الاشتراكات والمنصة** | `test/subscription_widgets_test.dart` & `test/platform_widgets_test.dart` | كروت استهلاك الحصص، خطط الترقية، حماية مركز المنصة للمشرفين |
| **المكونات المشتركة** | `test/common_ui_widgets_test.dart` | سلامة وسلوك مكونات `MujeebCard`, `StatusBadge`, `MetricStatCard`, `MujeebButton` |

---

## 7. الترتيب المقترح لمراحل التنفيذ (Execution Phasing Strategy)

وفق مبدأ تقليل المخاطر وضمان عدم كسر أي وظيفة أثناء التحسين البصري:

```
المرحلة 1: المحادثات وصندوق الوارد (Inbox & Conversation Detail) [نواة تجربة التاجر]
    └── conversation_detail_screen.dart + inbox_tab.dart
         ▼
المرحلة 2: لوحة التحكم الرئيسية (Home Dashboard Tab)
    └── dashboard_tab.dart + merchant_home_screen.dart (AppBar & Navigation Bar)
         ▼
المرحلة 3: إدارة علاقات العملاء والفرص (CRM: Customers & Leads)
    └── customers_tab.dart + customer_detail_screen.dart + leads_tab.dart + lead_detail_screen.dart
         ▼
المرحلة 4: المبيعات والمعاملات التجارية (Sales & Transactions)
    └── transactions_screen.dart + transaction_detail_screen.dart + transaction_draft_form_screen.dart
         ▼
المرحلة 5: الكتالوج والمنتجات والقنوات والأتمتة (Catalog & Channels)
    └── catalogs_screen.dart + catalog_items_screen.dart + channels_screen.dart + ai_decisions_screen.dart
         ▼
المرحلة 6: الإعدادات، الفريق، الاشتراكات، والمصادقة (Settings, Team, Subscription & Auth)
    └── business_settings_tab.dart + team_screen.dart + subscription_screen.dart + login_screen.dart
```

---

## 8. الخاتمة وجاهزية الانتقال للمرحلة القادمة

تمت قراءة وتحليل مشروع Mujeeb24 بالكامل، واستخراج خريطة الـ 32 شاشة ومكونات العرض المشتركة، وربطها بالمراجع البصرية بدقة متناهية، والتحقق من سلامة كافة الاختبارات بنسبة 100%.

**تم إيقاف العمل في هذه المرحلة امتثالاً للأمر، وبانتظار برومبت المرحلة التنفيذية المحددة.**
