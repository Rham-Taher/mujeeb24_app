import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/channels/channel_automation_repository.dart';
import 'package:mujeeb24_app/core/models/channel_automation_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/channels/presentation/ai_decisions_screen.dart';
import 'package:mujeeb24_app/features/channels/presentation/automation_rules_screen.dart';
import 'package:mujeeb24_app/features/channels/presentation/canned_replies_screen.dart';
import 'package:mujeeb24_app/features/channels/presentation/channels_screen.dart';
import 'package:mujeeb24_app/features/channels/providers/channel_automation_provider.dart';

class FakeChannelAutomationRepository extends ChannelAutomationRepository {
  List<ChannelConnection> mockConnections;
  List<Capability> mockCapabilities;
  ChannelHistorySummary? mockPurgeSummary;
  List<AutomationRule> mockRules;
  List<AIDecision> mockDecisions;
  List<CannedReply> mockReplies;

  bool listConnectionsCalled = false;
  bool beginConnectionCalled = false;
  bool reconnectCalled = false;
  bool disconnectCalled = false;
  bool previewPurgeCalled = false;
  bool purgeCalled = false;
  bool listRulesCalled = false;
  bool createRuleCalled = false;
  bool updateRuleCalled = false;
  bool listDecisionsCalled = false;
  bool requestHumanCalled = false;
  bool listRepliesCalled = false;
  bool createReplyCalled = false;
  bool updateReplyCalled = false;

  FakeChannelAutomationRepository({
    this.mockConnections = const [],
    this.mockCapabilities = const [],
    this.mockPurgeSummary,
    this.mockRules = const [],
    this.mockDecisions = const [],
    this.mockReplies = const [],
  }) : super(apiClient: ApiClient(baseUrl: 'https://mock.local'));

  @override
  Future<ChannelConnectionPage> listChannelConnections({
    required String businessId,
    String? status,
    String? channel,
    String? cursor,
    int limit = 25,
  }) async {
    listConnectionsCalled = true;
    return ChannelConnectionPage(items: mockConnections);
  }

  @override
  Future<List<Capability>> getConnectionCapabilities({
    required String businessId,
    required String connectionId,
  }) async {
    return mockCapabilities;
  }

  @override
  Future<ChannelHistorySummary> previewChannelHistoryPurge({
    required String businessId,
    required String connectionId,
  }) async {
    previewPurgeCalled = true;
    return mockPurgeSummary ??
        ChannelHistorySummary(
          businessId: businessId,
          connectionId: connectionId,
          conversations: 25,
          messages: 310,
        );
  }

  @override
  Future<ChannelHistorySummary> purgeChannelHistory({
    required String businessId,
    required String connectionId,
    required String expectedVersion,
    String confirmation = PurgeChannelHistoryRequest.requiredConfirmation,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    purgeCalled = true;
    return ChannelHistorySummary(
      businessId: businessId,
      connectionId: connectionId,
      conversations: 0,
      messages: 0,
      purgedAt: '2026-10-18T22:00:00Z',
    );
  }

  @override
  Future<ChannelConnection> reconnectChannel({
    required String businessId,
    required String connectionId,
    required String reason,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    reconnectCalled = true;
    return mockConnections.firstWhere((c) => c.id == connectionId);
  }

  @override
  Future<ChannelConnection> disconnectChannel({
    required String businessId,
    required String connectionId,
    required String reason,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    disconnectCalled = true;
    return mockConnections.firstWhere((c) => c.id == connectionId);
  }

  @override
  Future<AutomationRulePage> listAutomationRules({
    required String businessId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    listRulesCalled = true;
    return AutomationRulePage(items: mockRules);
  }

  @override
  Future<AutomationRule> createAutomationRule({
    required String businessId,
    required CreateAutomationRuleRequest request,
    String? idempotencyKey,
  }) async {
    createRuleCalled = true;
    final created = AutomationRule(
      id: 'new-rule-1',
      businessId: businessId,
      name: request.name,
      status: 'active',
      triggerKind: request.triggerKind,
      conditions: request.conditions,
      actionKind: request.actionKind,
      actionPayload: request.actionPayload,
      position: 1,
      resourceVersion: '1',
    );
    mockRules.add(created);
    return created;
  }

  @override
  Future<AutomationRule> updateAutomationRule({
    required String businessId,
    required String automationRuleId,
    required UpdateAutomationRuleRequest request,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    updateRuleCalled = true;
    final existing = mockRules.firstWhere((r) => r.id == automationRuleId);
    final updated = AutomationRule(
      id: existing.id,
      businessId: existing.businessId,
      name: request.name ?? existing.name,
      status: request.status ?? existing.status,
      triggerKind: existing.triggerKind,
      conditions: request.conditions ?? existing.conditions,
      actionKind: request.actionKind ?? existing.actionKind,
      actionPayload: request.actionPayload ?? existing.actionPayload,
      position: request.position ?? existing.position,
      resourceVersion: '2',
    );
    return updated;
  }

  @override
  Future<AIDecisionPage> listAIDecisions({
    required String businessId,
    String? lifecycle,
    String? conversationId,
    bool? requiresHuman,
    String? cursor,
    int limit = 25,
  }) async {
    listDecisionsCalled = true;
    var list = mockDecisions;
    if (requiresHuman != null) {
      list = list.where((d) => d.requiresHuman == requiresHuman).toList();
    }
    return AIDecisionPage(items: list);
  }

  @override
  Future<AIDecision> requestHumanReview({
    required String businessId,
    required String decisionId,
    required String reason,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    requestHumanCalled = true;
    final existing = mockDecisions.firstWhere((d) => d.id == decisionId);
    return AIDecision(
      id: existing.id,
      businessId: existing.businessId,
      conversationId: existing.conversationId,
      intentBase: existing.intentBase,
      entities: existing.entities,
      requiresHuman: true,
      lifecycle: 'human_requested',
    );
  }

  @override
  Future<List<CannedReply>> listCannedReplies({
    required String businessId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    listRepliesCalled = true;
    return mockReplies;
  }

  @override
  Future<CannedReply> createCannedReply({
    required String businessId,
    required CreateCannedReplyRequest request,
    String? idempotencyKey,
  }) async {
    createReplyCalled = true;
    final created = CannedReply(
      id: 'new-reply-1',
      businessId: businessId,
      title: request.title,
      shortcut: request.shortcut,
      body: request.body,
      status: 'active',
      resourceVersion: '1',
    );
    mockReplies.add(created);
    return created;
  }

  @override
  Future<CannedReply> updateCannedReply({
    required String businessId,
    required String cannedReplyId,
    required UpdateCannedReplyRequest request,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    updateReplyCalled = true;
    final existing = mockReplies.firstWhere((r) => r.id == cannedReplyId);
    return CannedReply(
      id: existing.id,
      businessId: existing.businessId,
      title: request.title ?? existing.title,
      shortcut: request.shortcut ?? existing.shortcut,
      body: request.body ?? existing.body,
      status: request.status ?? existing.status,
      resourceVersion: '2',
    );
  }
}

Widget createTestableWidget({required Widget child}) {
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
  const testBusinessId = 'b1111111-1111-1111-1111-111111111111';

  group('Phase 6 ChannelsScreen Widget Tests', () {
    testWidgets('renders channel list, status badge, and navigation chips', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(
        mockConnections: [
          const ChannelConnection(
            id: 'conn-1',
            businessId: testBusinessId,
            provider: 'meta',
            channel: 'whatsapp',
            status: 'active',
            externalAccountReference: 'WhatsApp Support',
            resourceVersion: '1',
          ),
          const ChannelConnection(
            id: 'conn-2',
            businessId: testBusinessId,
            provider: 'telegram',
            channel: 'telegram',
            status: 'disconnected',
            externalAccountReference: 'Telegram Bot',
            resourceVersion: '2',
          ),
        ],
      );

      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: ChannelsScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Support'), findsOneWidget);
      expect(find.text('متصل ونشط'), findsOneWidget);
      expect(find.text('Telegram Bot'), findsOneWidget);
      expect(find.text('غير متصل'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('قرارات الذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('قواعد الأتمتة'), findsOneWidget);
      expect(find.text('الردود الجاهزة'), findsOneWidget);
    });

    testWidgets('history purge preview and confirmation flow executes correctly', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(
        mockConnections: [
          const ChannelConnection(
            id: 'conn-1',
            businessId: testBusinessId,
            provider: 'meta',
            channel: 'whatsapp',
            status: 'active',
            externalAccountReference: 'Support Line',
            resourceVersion: 'ver-3',
          ),
        ],
        mockPurgeSummary: const ChannelHistorySummary(
          businessId: testBusinessId,
          connectionId: 'conn-1',
          conversations: 40,
          messages: 350,
        ),
      );

      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: ChannelsScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      // Tap purge history chip
      final purgeChip = find.text('حذف سجل القناة');
      expect(purgeChip, findsOneWidget);
      await tester.tap(purgeChip);
      await tester.pumpAndSettle();

      // Verify preview dialog showed counts
      expect(fakeRepo.previewPurgeCalled, isTrue);
      expect(find.text('معاينة حذف سجل القناة'), findsOneWidget);
      expect(find.text('المحادثات المتأثرة: 40'), findsOneWidget);
      expect(find.text('الرسائل المتأثرة: 350'), findsOneWidget);

      // Enter invalid confirmation
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, 'WRONG_CONFIRM');
      await tester.tap(find.widgetWithText(ElevatedButton, 'حذف سجل القناة'));
      await tester.pumpAndSettle();

      expect(find.text('نص التأكيد غير مطابق بدقة'), findsOneWidget);
      expect(fakeRepo.purgeCalled, isFalse);

      // Enter exact confirmation string
      await tester.enterText(inputField, 'DELETE_ALL_CHANNEL_HISTORY');
      await tester.tap(find.widgetWithText(ElevatedButton, 'حذف سجل القناة'));
      await tester.pumpAndSettle();

      expect(fakeRepo.purgeCalled, isTrue);
      expect(find.text('تم حذف سجل القناة بالكامل بنجاح'), findsOneWidget);
    });
  });

  group('Phase 6 AutomationRulesScreen Widget Tests', () {
    testWidgets('renders rules list and allows toggling status', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(
        mockRules: [
          const AutomationRule(
            id: 'rule-1',
            businessId: testBusinessId,
            name: 'تصنيف العملاء المميزين',
            status: 'active',
            triggerKind: 'inbound_message',
            actionKind: 'add_label',
            actionPayload: {'label': 'VIP'},
            position: 1,
            resourceVersion: '1',
          ),
        ],
      );

      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: AutomationRulesScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('تصنيف العملاء المميزين'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(fakeRepo.updateRuleCalled, isTrue);
    });

    testWidgets('opens create rule dialog and submits successfully', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(mockRules: []);
      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: AutomationRulesScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('لا توجد قواعد أتمتة مضافة'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة قاعدة جديدة'));
      await tester.pumpAndSettle();

      // Enter name and action parameter
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'قاعدة التعيين التلقائي');
      await tester.enterText(textFields.at(2), 'Support Team');

      await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة قاعدة جديدة').last);
      await tester.pumpAndSettle();

      expect(fakeRepo.createRuleCalled, isTrue);
      expect(find.text('تم إنشاء قاعدة الأتمتة بنجاح'), findsOneWidget);
    });
  });

  group('Phase 6 AIDecisionsScreen Widget Tests', () {
    testWidgets('renders decisions list and displays human review action', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(
        mockDecisions: [
          const AIDecision(
            id: 'dec-1',
            businessId: testBusinessId,
            intentBase: 'inquire_catalog_offer',
            requiresHuman: true,
            lifecycle: 'suggested',
            entities: {'product': 'قهوة'},
          ),
        ],
      );

      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: AIDecisionsScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('inquire_catalog_offer'), findsOneWidget);
      expect(find.text('يتطلب مراجعة بشرية'), findsOneWidget);
      expect(find.text('طلب مراجعة بشرية'), findsOneWidget);

      // Request human review
      await tester.tap(find.text('طلب مراجعة بشرية'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'طلب مراجعة بشرية'));
      await tester.pumpAndSettle();

      expect(fakeRepo.requestHumanCalled, isTrue);
      expect(find.text('تم إرسال طلب المراجعة البشرية بنجاح'), findsOneWidget);
    });
  });

  group('Phase 6 CannedRepliesScreen Widget Tests', () {
    testWidgets('renders canned replies list and creates new reply', (tester) async {
      final fakeRepo = FakeChannelAutomationRepository(
        mockReplies: [
          const CannedReply(
            id: 'cr-1',
            businessId: testBusinessId,
            title: 'رسالة الترحيب',
            shortcut: '/welcome',
            body: 'مرحباً بك في مجيب 24',
            status: 'active',
            resourceVersion: '1',
          ),
        ],
      );

      final provider = ChannelAutomationProvider(repository: fakeRepo);

      await tester.pumpWidget(createTestableWidget(
        child: CannedRepliesScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('/welcome'), findsOneWidget);
      expect(find.text('رسالة الترحيب'), findsOneWidget);
      expect(find.text('مرحباً بك في مجيب 24'), findsOneWidget);

      // Tap create
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '/support');
      await tester.enterText(fields.at(1), 'دعم فني');
      await tester.enterText(fields.at(2), 'نحن هنا لمساعدتك');

      await tester.tap(find.widgetWithText(ElevatedButton, 'إضافة رد جاهز'));
      await tester.pumpAndSettle();

      expect(fakeRepo.createReplyCalled, isTrue);
      expect(find.text('تم إنشاء الرد الجاهز بنجاح'), findsOneWidget);
    });
  });
}
