import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/channels/channel_automation_repository.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/channel_automation_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/channels/presentation/ai_decisions_screen.dart';
import 'package:mujeeb24_app/features/channels/providers/channel_automation_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/conversation_detail_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class Phase4MockMerchantRepo extends MerchantRepository {
  final List<Message> mockMessages;
  final Conversation mockConversation;
  final List<CannedReply> mockCannedReplies;

  Phase4MockMerchantRepo({
    required this.mockMessages,
    required this.mockConversation,
    required this.mockCannedReplies,
  }) : super(apiClient: ApiClient());

  @override
  Future<Conversation> getConversation({
    required String businessId,
    required String conversationId,
  }) async {
    return mockConversation;
  }

  @override
  Future<Conversation> markConversationRead({
    required String businessId,
    required String conversationId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    return mockConversation;
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
}

class Phase4MockChannelRepo extends ChannelAutomationRepository {
  final List<AIDecision> mockDecisions;

  Phase4MockChannelRepo({
    required this.mockDecisions,
  }) : super(apiClient: ApiClient());

  @override
  Future<AIDecisionPage> listAIDecisions({
    required String businessId,
    String? lifecycle,
    String? conversationId,
    bool? requiresHuman,
    String? cursor,
    int limit = 25,
  }) async {
    final items = requiresHuman == true
        ? mockDecisions.where((d) => d.requiresHuman).toList()
        : mockDecisions;
    return AIDecisionPage(items: items);
  }
}

Future<void> captureWidgetScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filePath,
) async {
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 Visual Capture Tests', () {
    testWidgets('Capture ConversationDetailScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final mockConv = const Conversation(
        id: 'conv_8819',
        businessId: 'biz_01',
        customer: CustomerSummary(
          id: 'cust_4421',
          displayName: 'سارة أحمد الكردي',
        ),
        state: 'open',
        ownership: 'assigned',
        aiMode: 'auto',
        priority: 'high',
        lastActivityAt: '2026-10-24T10:15:00Z',
        resourceVersion: 'v2',
        labels: ['عميل VIP', 'طلب عاجل'],
        assignment: {
          'principal_id': 'agent_01',
          'principal_name': 'عمر خالد (خدمة العملاء)',
        },
      );

      final mockMessages = [
        const Message(
          id: 'm1',
          conversationId: 'conv_8819',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'السلام عليكم ورحمة الله، هل المنتج متوفر للشحن اليوم إلى الرياض؟',
          occurredAt: '2026-10-24T10:00:00Z',
          createdAt: '2026-10-24T10:00:00Z',
        ),
        const Message(
          id: 'm2',
          conversationId: 'conv_8819',
          direction: 'outbound',
          origin: 'human_agent',
          status: 'delivered',
          text: 'أهلاً بك أختي سارة! نعم متاح والتوصيل فوري خلال 24 ساعة عبر مندوب خاص.',
          occurredAt: '2026-10-24T10:02:00Z',
          createdAt: '2026-10-24T10:02:00Z',
        ),
        const Message(
          id: 'm3',
          conversationId: 'conv_8819',
          direction: 'outbound',
          origin: 'human_agent',
          status: 'accepted',
          text: 'ملاحظة خاصة: تم التنسيق مع المستودع وتأكيد إرفاق عينة مجانية للعميل.',
          private: true,
          occurredAt: '2026-10-24T10:05:00Z',
          createdAt: '2026-10-24T10:05:00Z',
        ),
        const Message(
          id: 'm4',
          conversationId: 'conv_8819',
          direction: 'inbound',
          origin: 'customer',
          status: 'delivered',
          text: 'ممتاز جدًا، اعتمدوا الطلب رجاءً. شكرًا لسرعة تجاوبكم.',
          occurredAt: '2026-10-24T10:08:00Z',
          createdAt: '2026-10-24T10:08:00Z',
        ),
      ];

      final mockCanned = [
        const CannedReply(
          id: 'cr_1',
          businessId: 'biz_01',
          title: 'الترحيب الأولي',
          shortcut: '/welcome',
          body: 'أهلاً بك في مجيب 24! كيف يمكننا مساعدتك اليوم؟',
          status: 'active',
          resourceVersion: '1',
        ),
      ];

      final repo = Phase4MockMerchantRepo(
        mockMessages: mockMessages,
        mockConversation: mockConv,
        mockCannedReplies: mockCanned,
      );
      final provider = MerchantProvider(merchantRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RepaintBoundary(
            key: key,
            child: ConversationDetailScreen(
              merchantProvider: provider,
              businessId: 'biz_01',
              conversationId: 'conv_8819',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase4_conversation_detail.png');
      expect(File('docs/renders/phase4_conversation_detail.png').existsSync(), isTrue);
    });

    testWidgets('Capture AIDecisionsScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      final mockDecisions = [
        const AIDecision(
          id: 'dec_ai_9901',
          businessId: 'biz_01',
          conversationId: 'conv_8819',
          intentBase: 'inquire_catalog_offer',
          lifecycle: 'suggested',
          requiresHuman: true,
          entities: {
            'product': 'قهوة مختصة كولومبية',
            'package_size': '250g',
            'discount': '15%',
          },
          requestedAction: 'apply_custom_discount',
          missingInformation: ['customer_loyalty_tier'],
        ),
        const AIDecision(
          id: 'dec_ai_9902',
          businessId: 'biz_01',
          conversationId: 'conv_8820',
          intentBase: 'confirm_order_transaction',
          lifecycle: 'executed',
          requiresHuman: false,
          entities: {
            'order_id': 'ORD-9842',
            'payment_method': 'mada',
            'amount': '145.00 SAR',
          },
          effectiveCapability: 'auto_transaction_draft',
        ),
        const AIDecision(
          id: 'dec_ai_9903',
          businessId: 'biz_01',
          conversationId: 'conv_8821',
          intentBase: 'check_delivery_coverage',
          lifecycle: 'completed',
          requiresHuman: false,
          entities: {
            'city': 'الرياض',
            'district': 'الملقا',
            'service': 'same_day_delivery',
          },
        ),
      ];

      final repo = Phase4MockChannelRepo(mockDecisions: mockDecisions);
      final provider = ChannelAutomationProvider(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RepaintBoundary(
            key: key,
            child: AIDecisionsScreen(
              channelProvider: provider,
              businessId: 'biz_01',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase4_ai_decisions.png');
      expect(File('docs/renders/phase4_ai_decisions.png').existsSync(), isTrue);
    });
  });
}
