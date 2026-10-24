import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/business_settings_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/conversation_detail_screen.dart';
import 'package:mujeeb24_app/features/merchant/presentation/dashboard_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/inbox_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/merchant_home_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class FakeMerchantRepository extends MerchantRepository {
  DashboardOverview? mockOverview;
  Business? mockBusiness;
  BusinessPolicy? mockPolicy;
  List<Conversation> mockConversations;
  List<Message> mockMessages;
  List<CannedReply> mockCannedReplies;

  FakeMerchantRepository({
    this.mockOverview,
    this.mockBusiness,
    this.mockPolicy,
    this.mockConversations = const [],
    this.mockMessages = const [],
    this.mockCannedReplies = const [],
  }) : super(apiClient: ApiClient());

  @override
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    return mockOverview ??
        const DashboardOverview(
          openConversations: 7,
          waitingHuman: 2,
          newCustomers: 12,
          newLeads: 5,
          transactionsNeedingReview: 1,
          connections: {'WhatsApp': 5, 'Instagram': 2},
        );
  }

  @override
  Future<Business> getBusinessProfile(String businessId) async {
    return mockBusiness ??
        const Business(
          id: 'biz_01',
          name: 'مؤسسة الأفق للتجارة',
          slug: 'alufuq-corp',
          defaultCurrency: 'SAR',
          locale: 'ar',
          timezone: 'Asia/Riyadh',
        );
  }

  @override
  Future<BusinessPolicy> getBusinessPolicy(String businessId) async {
    return mockPolicy ??
        const BusinessPolicy(
          businessId: 'biz_01',
          aiMode: 'suggest',
          defaultHumanReview: true,
          allowAutoReply: false,
          allowAutoLeadCreation: true,
          allowAutoTransactionDraft: true,
          allowAutoConfirmation: false,
          resourceVersion: 'v1',
        );
  }

  @override
  Future<List<Conversation>> listConversations({
    required String businessId,
    int limit = 25,
    String? cursor,
    String? state,
    String? ownership,
    String? channel,
    String? customerId,
  }) async {
    return mockConversations;
  }

  @override
  Future<Conversation> getConversation({
    required String businessId,
    required String conversationId,
  }) async {
    return mockConversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation(
        id: conversationId,
        businessId: businessId,
        customer: const CustomerSummary(
          id: 'c_default',
          displayName: 'سارة أحمد',
        ),
        state: 'waiting_human',
        ownership: 'unassigned',
        aiMode: 'off',
        priority: 'high',
        lastActivityAt: '2026-10-15T10:00:00Z',
        resourceVersion: 'v1',
        labels: ['vip'],
      ),
    );
  }

  @override
  Future<List<Message>> listMessages({
    required String businessId,
    required String conversationId,
    int limit = 50,
    String? cursor,
  }) async {
    return mockMessages;
  }

  @override
  Future<Message> sendMessage({
    required String businessId,
    required String conversationId,
    required String text,
    String? idempotencyKey,
  }) async {
    return Message(
      id: 'msg_new',
      conversationId: conversationId,
      direction: 'outbound',
      origin: 'human_agent',
      status: 'delivered',
      text: text,
      private: false,
      createdAt: '2026-10-15T12:00:00Z',
    );
  }

  @override
  Future<Message> addPrivateNote({
    required String businessId,
    required String conversationId,
    required String text,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    return Message(
      id: 'note_new',
      conversationId: conversationId,
      direction: 'outbound',
      origin: 'human_agent',
      status: 'accepted',
      text: text,
      private: true,
      createdAt: '2026-10-15T12:00:00Z',
    );
  }

  @override
  Future<Conversation> markConversationRead({
    required String businessId,
    required String conversationId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    return getConversation(
      businessId: businessId,
      conversationId: conversationId,
    );
  }

  @override
  Future<List<CannedReply>> listCannedReplies({
    required String businessId,
    int limit = 50,
  }) async {
    return mockCannedReplies;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(apiClient: ApiClient());
}

class FakeWorkspaceRepository extends WorkspaceRepository {
  FakeWorkspaceRepository() : super(apiClient: ApiClient());
}

Widget buildTestApp({required Widget child}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  const testBusiness = Business(
    id: 'biz_01',
    name: 'مؤسسة الأفق للتجارة',
    slug: 'alufuq-corp',
    defaultCurrency: 'SAR',
    locale: 'ar',
    timezone: 'Asia/Riyadh',
  );

  group('Phase 2 Widget Tests: DashboardTab', () {
    testWidgets('renders Dashboard overview metrics and channels banner', (
      tester,
    ) async {
      final fakeRepo = FakeMerchantRepository(
        mockOverview: const DashboardOverview(
          openConversations: 18,
          waitingHuman: 6,
          newCustomers: 30,
          newLeads: 12,
          transactionsNeedingReview: 2,
          connections: {'واتساب': 15, 'إنستغرام': 3},
        ),
      );
      final provider = MerchantProvider(merchantRepository: fakeRepo);

      bool navigatedToInbox = false;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: DashboardTab(
              merchantProvider: provider,
              currentBusiness: testBusiness,
              onNavigateToInbox: () => navigatedToInbox = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check business name
      expect(find.text('مؤسسة الأفق للتجارة'), findsOneWidget);

      // Check metrics
      expect(find.text('18'), findsOneWidget); // Open conversations
      expect(find.text('6'), findsOneWidget); // Waiting human
      expect(find.text('30'), findsOneWidget); // New customers
      expect(find.text('12'), findsOneWidget); // New leads

      // Check channels list
      expect(find.text('واتساب'), findsOneWidget);
      expect(find.text('15 محادثة'), findsOneWidget);
      expect(find.text('إنستغرام'), findsOneWidget);
      expect(find.text('3 محادثة'), findsOneWidget);

      // Tap metric to navigate
      await tester.tap(find.text('18'));
      expect(navigatedToInbox, true);
    });
  });

  group('Phase 2 Widget Tests: InboxTab', () {
    testWidgets(
      'renders conversation list, filter chips, and search filtering',
      (tester) async {
        final mockList = [
          const Conversation(
            id: 'conv_1',
            businessId: 'biz_01',
            customer: CustomerSummary(id: 'c_1', displayName: 'سارة أحمد'),
            state: 'waiting_human',
            ownership: 'unassigned',
            aiMode: 'off',
            priority: 'high',
            lastActivityAt: '2026-10-15T10:00:00Z',
            resourceVersion: 'v1',
            labels: ['طلب عاجل'],
          ),
          const Conversation(
            id: 'conv_2',
            businessId: 'biz_01',
            customer: CustomerSummary(id: 'c_2', displayName: 'خالد عبدالله'),
            state: 'open',
            ownership: 'assigned',
            aiMode: 'auto',
            priority: 'normal',
            lastActivityAt: '2026-10-15T09:00:00Z',
            resourceVersion: 'v1',
            labels: ['استفسار'],
          ),
        ];

        final fakeRepo = FakeMerchantRepository(mockConversations: mockList);
        final provider = MerchantProvider(merchantRepository: fakeRepo);

        Conversation? selected;

        await tester.pumpWidget(
          buildTestApp(
            child: Scaffold(
              body: InboxTab(
                merchantProvider: provider,
                currentBusiness: testBusiness,
                onConversationSelected: (c) => selected = c,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Both conversations visible
        expect(find.text('سارة أحمد'), findsOneWidget);
        expect(find.text('خالد عبدالله'), findsOneWidget);
        expect(find.text('#طلب عاجل'), findsOneWidget);

        // Filter by 'بانتظار بشري'
        await tester.tap(find.widgetWithText(ChoiceChip, 'بانتظار بشري'));
        await tester.pumpAndSettle();

        expect(find.text('سارة أحمد'), findsOneWidget);
        expect(find.text('خالد عبدالله'), findsNothing);

        // Reset to 'الكل'
        await tester.tap(find.widgetWithText(ChoiceChip, 'الكل'));
        await tester.pumpAndSettle();
        expect(find.text('خالد عبدالله'), findsOneWidget);

        // Search field test
        await tester.enterText(find.byType(TextField), 'خالد');
        await tester.pumpAndSettle();

        expect(find.text('خالد عبدالله'), findsOneWidget);
        expect(find.text('سارة أحمد'), findsNothing);

        // Tap conversation to open
        await tester.tap(find.text('خالد عبدالله'));
        expect(selected?.id, 'conv_2');
      },
    );
  });

  group('Phase 2 Widget Tests: ConversationDetailScreen', () {
    testWidgets(
      'renders timeline, distinguishes private note visually, and sends message',
      (tester) async {
        final messages = [
          const Message(
            id: 'm1',
            conversationId: 'conv_1',
            direction: 'inbound',
            origin: 'customer',
            status: 'delivered',
            text: 'السلام عليكم، هل التوصيل متوفر للرياض؟',
            private: false,
            createdAt: '2026-10-15T10:00:00Z',
          ),
          const Message(
            id: 'm2',
            conversationId: 'conv_1',
            direction: 'outbound',
            origin: 'human_agent',
            status: 'delivered',
            text: 'وعليكم السلام، نعم متوفر خلال 24 ساعة.',
            private: false,
            createdAt: '2026-10-15T10:02:00Z',
          ),
          const Message(
            id: 'm3',
            conversationId: 'conv_1',
            direction: 'outbound',
            origin: 'human_agent',
            status: 'accepted',
            text: 'العميل يطلب مندوب خاص قبل الظهر.',
            private: true,
            createdAt: '2026-10-15T10:05:00Z',
          ),
        ];

        final fakeRepo = FakeMerchantRepository(mockMessages: messages);
        final provider = MerchantProvider(merchantRepository: fakeRepo);

        await tester.pumpWidget(
          buildTestApp(
            child: ConversationDetailScreen(
              merchantProvider: provider,
              businessId: 'biz_01',
              conversationId: 'conv_1',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check messages
        expect(
          find.text('السلام عليكم، هل التوصيل متوفر للرياض؟'),
          findsOneWidget,
        );
        expect(
          find.text('وعليكم السلام، نعم متوفر خلال 24 ساعة.'),
          findsOneWidget,
        );

        // Check private note visual distinction (badge and text)
        expect(find.text('العميل يطلب مندوب خاص قبل الظهر.'), findsOneWidget);
        expect(find.text('ملاحظة خاصة'), findsOneWidget);

        // Toggle to Private Note mode
        await tester.tap(find.text('ملاحظة داخلية'));
        await tester.pumpAndSettle();

        expect(find.text('اكتب ملاحظة داخلية خاصة بالفريق...'), findsOneWidget);

        // Enter private note text and send
        await tester.enterText(
          find.byType(TextField),
          'تم الاتصال بالعميل وتأكيد الموعد',
        );
        await tester.tap(find.byType(IconButton).last);
        await tester.pumpAndSettle();

        // New private note appears in list
        expect(find.text('تم الاتصال بالعميل وتأكيد الموعد'), findsOneWidget);
      },
    );
  });

  group('Phase 2 Widget Tests: BusinessSettingsTab', () {
    testWidgets('renders business profile and AI policy toggles', (
      tester,
    ) async {
      final fakeRepo = FakeMerchantRepository();
      final provider = MerchantProvider(merchantRepository: fakeRepo);

      bool switchedBusiness = false;
      bool loggedOut = false;
      bool toggledLang = false;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: BusinessSettingsTab(
              merchantProvider: provider,
              currentBusiness: testBusiness,
              onSwitchBusiness: () => switchedBusiness = true,
              onLogout: () => loggedOut = true,
              onToggleLanguage: () => toggledLang = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Business fields
      expect(find.text('مؤسسة الأفق للتجارة'), findsOneWidget);
      expect(find.text('SAR'), findsOneWidget);

      // AI Mode & Policy Switches
      expect(find.text('سياسة الذكاء الاصطناعي والمراجعة'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(5));

      // Account actions
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      expect(toggledLang, true);

      await tester.tap(find.text('اختر النشاط التجاري'));
      expect(switchedBusiness, true);

      await tester.tap(find.text('تسجيل الخروج'));
      expect(loggedOut, true);
    });
  });

  group('Phase 2 Widget Tests: MerchantHomeScreen', () {
    testWidgets('navigates across Home, Inbox, and Settings tabs', (
      tester,
    ) async {
      final fakeRepo = FakeMerchantRepository();
      final provider = MerchantProvider(merchantRepository: fakeRepo);

      final authProvider = AuthProvider(
        authRepository: FakeAuthRepository(),
        workspaceRepository: FakeWorkspaceRepository(),
      );
      authProvider.selectBusiness(
        const BusinessMembership(business: testBusiness, permissions: ['*']),
      );

      final localeProvider = AppLocaleProvider();

      await tester.pumpWidget(
        buildTestApp(
          child: MerchantHomeScreen(
            authProvider: authProvider,
            merchantProvider: provider,
            localeProvider: localeProvider,
            onSwitchBusiness: () {},
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Home (Dashboard)
      expect(find.text('مؤسسة الأفق للتجارة'), findsWidgets);
      expect(find.text('مؤشرات الأداء المباشرة'), findsOneWidget);

      // Tap Inbox tab in BottomNavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byIcon(Icons.forum_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('بحث بالعميل أو المعرف...'), findsOneWidget);

      // Tap Settings tab in BottomNavigationBar
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byIcon(Icons.settings_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الملف التعريفي للنشاط'), findsOneWidget);
    });
  });
}
