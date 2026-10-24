import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/merchant/presentation/conversation_detail_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class FakeOrderRepo extends MerchantRepository {
  List<Message> mockMessages;
  List<Conversation> mockConversations;
  List<CannedReply> mockCannedReplies;
  Message? lastSentMessage;
  Message? lastSentNote;
  Message? lastSentCanned;

  FakeOrderRepo({
    this.mockMessages = const [],
    this.mockConversations = const [],
    this.mockCannedReplies = const [],
  }) : super(apiClient: ApiClient());

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
        customer: const CustomerSummary(id: 'cust_1', displayName: 'عميل تجريبي'),
        state: 'waiting_human',
        ownership: 'unassigned',
        aiMode: 'off',
        priority: 'high',
        lastActivityAt: '2026-10-24T12:00:00Z',
        resourceVersion: 'v1',
      ),
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
  Future<List<Message>> listMessages({
    required String businessId,
    required String conversationId,
    int limit = 50,
    String? cursor,
  }) async {
    return mockMessages;
  }

  @override
  Future<List<CannedReply>> listCannedReplies({
    required String businessId,
    int limit = 50,
  }) async {
    return mockCannedReplies;
  }

  @override
  Future<Message> sendMessage({
    required String businessId,
    required String conversationId,
    required String text,
    String? idempotencyKey,
  }) async {
    final msg = Message(
      id: 'msg_sent_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      direction: 'outbound',
      origin: 'human_agent',
      status: 'delivered',
      text: text,
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    lastSentMessage = msg;
    return msg;
  }

  @override
  Future<Message> addPrivateNote({
    required String businessId,
    required String conversationId,
    required String text,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final note = Message(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      direction: 'outbound',
      origin: 'human_agent',
      status: 'delivered',
      private: true,
      text: text,
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    lastSentNote = note;
    return note;
  }

  @override
  Future<Message> sendCannedReply({
    required String businessId,
    required String conversationId,
    required String cannedReplyId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final canned = Message(
      id: 'canned_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      direction: 'outbound',
      origin: 'human_agent',
      status: 'delivered',
      text: 'رد سريع معتمد',
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    lastSentCanned = canned;
    return canned;
  }
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
  group('1. Message Model Ordering & Tie-Breaking Logic', () {
    test('effectiveDateTime prioritizes occurredAt over createdAt', () {
      final msg = const Message(
        id: 'm1',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T10:00:00Z',
        createdAt: '2026-10-24T10:05:00Z',
      );

      expect(msg.effectiveDateTime, DateTime.parse('2026-10-24T10:00:00Z'));
    });

    test('effectiveDateTime falls back to createdAt if occurredAt is null', () {
      final msg = const Message(
        id: 'm2',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        createdAt: '2026-10-24T10:05:00Z',
      );

      expect(msg.effectiveDateTime, DateTime.parse('2026-10-24T10:05:00Z'));
    });

    test('compareChronological sorts oldest to newest (ascending)', () {
      final mOld = const Message(
        id: 'm_old',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T09:00:00Z',
      );
      final mNew = const Message(
        id: 'm_new',
        conversationId: 'c1',
        direction: 'outbound',
        origin: 'human_agent',
        status: 'delivered',
        occurredAt: '2026-10-24T09:05:00Z',
      );

      final list = [mNew, mOld]..sort(Message.compareChronological);
      expect(list[0].id, 'm_old');
      expect(list[1].id, 'm_new');
    });

    test('compareChronological uses createdAt as secondary tie-breaker', () {
      final m1 = const Message(
        id: 'm1',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T10:00:00Z',
        createdAt: '2026-10-24T10:00:01Z',
      );
      final m2 = const Message(
        id: 'm2',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T10:00:00Z',
        createdAt: '2026-10-24T10:00:05Z',
      );

      final list = [m2, m1]..sort(Message.compareChronological);
      expect(list[0].id, 'm1');
      expect(list[1].id, 'm2');
    });

    test('compareChronological uses message id as deterministic tertiary tie-breaker', () {
      final mA = const Message(
        id: 'msg_001',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T10:00:00Z',
        createdAt: '2026-10-24T10:00:00Z',
      );
      final mB = const Message(
        id: 'msg_002',
        conversationId: 'c1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        occurredAt: '2026-10-24T10:00:00Z',
        createdAt: '2026-10-24T10:00:00Z',
      );

      final list = [mB, mA]..sort(Message.compareChronological);
      expect(list[0].id, 'msg_001');
      expect(list[1].id, 'msg_002');
    });
  });

  group('2. MerchantProvider Message Ordering & Backlog Sync', () {
    test('selectConversation converts backend descending order to UI ascending order', () async {
      final backendDescending = [
        const Message(
          id: 'msg_3',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'الرسالة الثالثة الأحدث',
          occurredAt: '2026-10-24T10:10:00Z',
        ),
        const Message(
          id: 'msg_2',
          conversationId: 'conv_1',
          direction: 'outbound',
          origin: 'human_agent',
          status: 'delivered',
          text: 'الرسالة الثانية المتوسطة',
          occurredAt: '2026-10-24T10:05:00Z',
        ),
        const Message(
          id: 'msg_1',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'الرسالة الأولى الأقدم',
          occurredAt: '2026-10-24T10:00:00Z',
        ),
      ];

      final repo = FakeOrderRepo(mockMessages: backendDescending);
      final provider = MerchantProvider(merchantRepository: repo);

      await provider.selectConversation(businessId: 'biz_1', conversationId: 'conv_1');

      expect(provider.messages.length, 3);
      // Index 0 must be oldest, index 2 must be newest
      expect(provider.messages[0].id, 'msg_1');
      expect(provider.messages[1].id, 'msg_2');
      expect(provider.messages[2].id, 'msg_3');
    });

    test('selectConversation deduplicates repeated messages from API', () async {
      final duplicateList = [
        const Message(
          id: 'msg_dup',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'مرحبا',
          occurredAt: '2026-10-24T10:00:00Z',
        ),
        const Message(
          id: 'msg_dup',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'مرحبا مكررة',
          occurredAt: '2026-10-24T10:00:00Z',
        ),
      ];

      final repo = FakeOrderRepo(mockMessages: duplicateList);
      final provider = MerchantProvider(merchantRepository: repo);

      await provider.selectConversation(businessId: 'biz_1', conversationId: 'conv_1');
      expect(provider.messages.length, 1);
    });

    test('switching conversation clears previous messages to prevent visual bleed', () async {
      final repo = FakeOrderRepo(
        mockMessages: [
          const Message(
            id: 'conv1_msg',
            conversationId: 'conv_1',
            direction: 'inbound',
            origin: 'customer',
            status: 'delivered',
            text: 'رسالة محادثة 1',
            occurredAt: '2026-10-24T10:00:00Z',
          ),
        ],
      );
      final provider = MerchantProvider(merchantRepository: repo);

      await provider.selectConversation(businessId: 'biz_1', conversationId: 'conv_1');
      expect(provider.messages.length, 1);

      provider.clearSelectedConversation();
      expect(provider.selectedConversation, isNull);
      expect(provider.messages.isEmpty, isTrue);
    });

    test('ingestMessages correctly places delayed/out-of-order backlog messages', () async {
      final repo = FakeOrderRepo(
        mockMessages: [
          const Message(
            id: 'msg_1',
            conversationId: 'conv_1',
            direction: 'inbound',
            origin: 'customer',
            status: 'delivered',
            text: 'أول رسالة 10:00',
            occurredAt: '2026-10-24T10:00:00Z',
          ),
          const Message(
            id: 'msg_3',
            conversationId: 'conv_1',
            direction: 'inbound',
            origin: 'customer',
            status: 'delivered',
            text: 'ثالث رسالة 10:10',
            occurredAt: '2026-10-24T10:10:00Z',
          ),
        ],
      );
      final provider = MerchantProvider(merchantRepository: repo);

      await provider.selectConversation(businessId: 'biz_1', conversationId: 'conv_1');
      expect(provider.messages.length, 2);

      // Backlog delayed message arrived out-of-order with occurredAt 10:05
      final delayedBacklogMsg = const Message(
        id: 'msg_2_backlog',
        conversationId: 'conv_1',
        direction: 'inbound',
        origin: 'customer',
        status: 'delivered',
        text: 'رسالة backlog وصلت متأخرة 10:05',
        occurredAt: '2026-10-24T10:05:00Z',
      );

      provider.ingestMessages('conv_1', [delayedBacklogMsg]);

      expect(provider.messages.length, 3);
      expect(provider.messages[0].id, 'msg_1');
      expect(provider.messages[1].id, 'msg_2_backlog');
      expect(provider.messages[2].id, 'msg_3');
    });

    test('loadMoreMessages merges older page without wiping current messages', () async {
      final repo = FakeOrderRepo(
        mockMessages: [
          const Message(
            id: 'msg_page2_newest',
            conversationId: 'conv_1',
            direction: 'inbound',
            origin: 'customer',
            status: 'delivered',
            occurredAt: '2026-10-24T10:30:00Z',
          ),
        ],
      );
      final provider = MerchantProvider(merchantRepository: repo);

      await provider.selectConversation(businessId: 'biz_1', conversationId: 'conv_1');
      expect(provider.messages.length, 1);
      expect(provider.messages.first.id, 'msg_page2_newest');

      // Now mock older messages for cursor pagination
      repo.mockMessages = [
        const Message(
          id: 'msg_page1_oldest',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          occurredAt: '2026-10-24T10:00:00Z',
        ),
      ];

      await provider.loadMoreMessages(businessId: 'biz_1', cursor: 'curs_123');

      expect(provider.messages.length, 2);
      expect(provider.messages[0].id, 'msg_page1_oldest');
      expect(provider.messages[1].id, 'msg_page2_newest');
    });
  });

  group('3. ConversationDetailScreen Chat UI Rendering Tests', () {
    testWidgets('renders messages in ascending order and displays time', (tester) async {
      final messages = [
        const Message(
          id: 'msg_1',
          conversationId: 'conv_1',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'مرحبًا، أحتاج استفسار عن طلبي',
          occurredAt: '2026-10-24T10:00:00Z',
          createdAt: '2026-10-24T10:00:00Z',
        ),
        const Message(
          id: 'msg_2',
          conversationId: 'conv_1',
          direction: 'outbound',
          origin: 'human_agent',
          status: 'delivered',
          text: 'أهلًا بك! كيف يمكنني مساعدتك اليوم؟',
          occurredAt: '2026-10-24T10:02:00Z',
          createdAt: '2026-10-24T10:02:00Z',
        ),
      ];

      final repo = FakeOrderRepo(mockMessages: messages);
      final provider = MerchantProvider(merchantRepository: repo);

      await tester.pumpWidget(
        buildTestApp(
          child: ConversationDetailScreen(
            businessId: 'biz_1',
            conversationId: 'conv_1',
            merchantProvider: provider,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('مرحبًا، أحتاج استفسار عن طلبي'), findsOneWidget);
      expect(find.text('أهلًا بك! كيف يمكنني مساعدتك اليوم؟'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
