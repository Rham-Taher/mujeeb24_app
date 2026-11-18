import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/channels/channel_automation_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/channel_automation_models.dart';
import 'package:mujeeb24_app/core/models/team_audit_models.dart';
import 'package:mujeeb24_app/core/team/team_audit_repository.dart';
import 'package:mujeeb24_app/features/channels/presentation/channels_screen.dart';
import 'package:mujeeb24_app/features/channels/providers/channel_automation_provider.dart';
import 'package:mujeeb24_app/features/team/presentation/team_screen.dart';
import 'package:mujeeb24_app/features/team/providers/team_audit_provider.dart';

class Phase8MockChannelRepo extends ChannelAutomationRepository {
  final List<ChannelConnection> mockConnections;

  Phase8MockChannelRepo({required this.mockConnections})
      : super(apiClient: ApiClient());

  @override
  Future<ChannelConnectionPage> listChannelConnections({
    required String businessId,
    String? status,
    String? channel,
    String? cursor,
    int limit = 25,
  }) async {
    return ChannelConnectionPage(items: mockConnections);
  }
}

class Phase8MockTeamRepo extends TeamAuditRepository {
  final List<TeamMember> mockMembers;
  final List<TeamInvitationDetails> mockInvitations;

  Phase8MockTeamRepo({
    required this.mockMembers,
    required this.mockInvitations,
  }) : super(apiClient: ApiClient());

  @override
  Future<TeamMemberPage> listTeamMembers({
    required String businessId,
    int limit = 25,
    String? cursor,
  }) async {
    return TeamMemberPage(
      items: mockMembers,
      pagination: const PaginationPage(hasMore: false),
      requestId: 'req-members',
    );
  }

  @override
  Future<TeamInvitationPage> listTeamInvitations({
    required String businessId,
    int limit = 25,
    String? cursor,
  }) async {
    return TeamInvitationPage(
      items: mockInvitations,
      pagination: const PaginationPage(hasMore: false),
      requestId: 'req-invitations',
    );
  }
}

Future<void> captureWidgetScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filePath,
) async {
  await tester.runAsync(() async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(buffer);
      }
    }
  });
}

Widget buildTestApp(Widget child, GlobalKey repaintKey) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087FF5)),
    ),
    home: RepaintBoundary(
      key: repaintKey,
      child: child,
    ),
  );
}

void main() {
  const testBusinessId = 'biz-phase8-test';

  testWidgets('Phase 8 Render Test: Channels Screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = Phase8MockChannelRepo(
      mockConnections: const [
        ChannelConnection(
          id: 'conn-wa-1',
          businessId: testBusinessId,
          provider: 'meta',
          channel: 'whatsapp',
          status: 'active',
          externalAccountReference: 'واتساب خدمة العملاء والطلبات',
          resourceVersion: '1',
        ),
        ChannelConnection(
          id: 'conn-ig-1',
          businessId: testBusinessId,
          provider: 'meta',
          channel: 'instagram',
          status: 'active',
          externalAccountReference: 'إنستغرام متجر مجيب الرسمي',
          resourceVersion: '1',
        ),
        ChannelConnection(
          id: 'conn-tg-1',
          businessId: testBusinessId,
          provider: 'telegram',
          channel: 'telegram',
          status: 'degraded',
          externalAccountReference: 'بوت الدعم الفني والتنبيهات',
          resourceVersion: '2',
        ),
        ChannelConnection(
          id: 'conn-fb-1',
          businessId: testBusinessId,
          provider: 'meta',
          channel: 'facebook',
          status: 'disconnected',
          externalAccountReference: 'فيسبوك مسنجر المبيعات',
          resourceVersion: '3',
        ),
      ],
    );

    final provider = ChannelAutomationProvider(repository: mockRepo);
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      buildTestApp(
        ChannelsScreen(
          channelProvider: provider,
          businessId: testBusinessId,
        ),
        repaintKey,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('واتساب خدمة العملاء والطلبات'), findsOneWidget);
    expect(find.text('إنستغرام متجر مجيب الرسمي'), findsOneWidget);
    expect(find.text('بوت الدعم الفني والتنبيهات', skipOffstage: false), findsOneWidget);

    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase8_channels.png',
    );
  });

  testWidgets('Phase 8 Render Test: Team Screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = Phase8MockTeamRepo(
      mockMembers: const [
        TeamMember(
          principalId: 'p-owner',
          email: 'owner@mujeeb24.com',
          displayName: 'عبدالله الأحمد (المالك)',
          role: TeamRoles.owner,
          permissions: [
            'team:manage',
            'catalog:write',
            'orders:manage',
          ],
          status: 'active',
        ),
        TeamMember(
          principalId: 'p-manager',
          email: 'sara.manager@mujeeb24.com',
          displayName: 'سارة خالد المنصور',
          role: TeamRoles.manager,
          permissions: [
            'catalog:write',
            'orders:manage',
          ],
          status: 'active',
        ),
        TeamMember(
          principalId: 'p-agent',
          email: 'fahad.agent@mujeeb24.com',
          displayName: 'فهد السبيعي',
          role: TeamRoles.agent,
          permissions: [
            'conversations:reply',
            'orders:create',
          ],
          status: 'active',
        ),
      ],
      mockInvitations: const [
        TeamInvitationDetails(
          id: 'inv-1',
          businessId: testBusinessId,
          email: 'invitee.analyst@mujeeb24.com',
          displayName: 'منى الزهراني',
          role: TeamRoles.analyst,
          permissions: ['analytics:view'],
          status: 'pending',
          invitedBy: 'p-owner',
          expiresAt: '2026-11-15T18:00:00Z',
          createdAt: '2026-11-01T10:00:00Z',
          updatedAt: '2026-11-01T10:00:00Z',
        ),
      ],
    );

    final provider = TeamAuditProvider(repository: mockRepo);
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      buildTestApp(
        TeamScreen(
          provider: provider,
          businessId: testBusinessId,
        ),
        repaintKey,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('عبدالله الأحمد (المالك)'), findsOneWidget);
    expect(find.text('سارة خالد المنصور'), findsOneWidget);

    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase8_team.png',
    );
  });
}
