import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/crm/crm_repository.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/features/crm/presentation/customers_tab.dart';
import 'package:mujeeb24_app/features/crm/presentation/leads_tab.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class Phase5MockCrmRepo extends CrmRepository {
  final List<Customer> mockCustomers;
  final List<Lead> mockLeads;

  Phase5MockCrmRepo({
    required this.mockCustomers,
    required this.mockLeads,
  }) : super(apiClient: ApiClient());

  @override
  Future<List<Customer>> listCustomers({
    required String businessId,
    String? search,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    return mockCustomers;
  }

  @override
  Future<List<Lead>> listLeads({
    required String businessId,
    String? status,
    String? customerId,
    String? scoreBand,
    String? cursor,
    int limit = 25,
  }) async {
    return mockLeads;
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

  group('Phase 5 Visual Capture Tests', () {
    testWidgets('Capture CustomersTab rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final mockCustomers = [
        const Customer(
          id: 'CUST-84920',
          businessId: 'biz_01',
          displayName: 'سارة أحمد الكردي',
          status: 'active',
          resourceVersion: 'v1',
          createdAt: '2026-10-15T10:00:00Z',
          updatedAt: '2026-10-15T10:00:00Z',
          contactPoints: [
            ContactPoint(
              kind: 'whatsapp',
              valueNormalized: '+966501234567',
              verificationStatus: 'verified',
            ),
            ContactPoint(
              kind: 'email',
              valueNormalized: 'sara.ahmad@example.com',
              verificationStatus: 'verified',
            ),
          ],
        ),
        const Customer(
          id: 'CUST-84921',
          businessId: 'biz_01',
          displayName: 'خالد بن عبدالعزيز السالم',
          status: 'active',
          resourceVersion: 'v1',
          createdAt: '2026-10-15T11:00:00Z',
          updatedAt: '2026-10-15T11:00:00Z',
          contactPoints: [
            ContactPoint(
              kind: 'telegram',
              valueNormalized: '+966551882299',
              verificationStatus: 'verified',
            ),
            ContactPoint(
              kind: 'email',
              valueNormalized: 'khaled.salem@company.sa',
              verificationStatus: 'verified',
            ),
          ],
        ),
        const Customer(
          id: 'CUST-84922',
          businessId: 'biz_01',
          displayName: 'مؤسسة الرواد التجارية',
          status: 'archived',
          resourceVersion: 'v1',
          createdAt: '2026-10-10T10:00:00Z',
          updatedAt: '2026-10-10T10:00:00Z',
          contactPoints: [
            ContactPoint(
              kind: 'phone',
              valueNormalized: '+966114455667',
              verificationStatus: 'unverified',
            ),
          ],
        ),
      ];

      final repo = Phase5MockCrmRepo(
        mockCustomers: mockCustomers,
        mockLeads: [],
      );
      final provider = CrmProvider(crmRepository: repo);

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
            child: CustomersTab(
              crmProvider: provider,
              businessId: 'biz_01',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase5_customers.png');
      expect(File('docs/renders/phase5_customers.png').existsSync(), isTrue);
    });

    testWidgets('Capture LeadsTab rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      final mockLeads = [
        const Lead(
          id: 'LEAD-9421',
          businessId: 'biz_01',
          customerId: 'CUST-84920',
          status: 'new',
          createdBy: 'agent_01',
          resourceVersion: 'v1',
          scoreBand: 'high',
          currentScore: 94.5,
        ),
        const Lead(
          id: 'LEAD-9422',
          businessId: 'biz_01',
          customerId: 'CUST-84921',
          status: 'qualified',
          createdBy: 'system_ai',
          resourceVersion: 'v2',
          scoreBand: 'high',
          currentScore: 88.0,
        ),
        const Lead(
          id: 'LEAD-9423',
          businessId: 'biz_01',
          customerId: 'CUST-84922',
          status: 'contacted',
          createdBy: 'agent_02',
          resourceVersion: 'v1',
          scoreBand: 'medium',
          currentScore: 65.0,
        ),
        const Lead(
          id: 'LEAD-9424',
          businessId: 'biz_01',
          customerId: 'CUST-84923',
          status: 'lost',
          createdBy: 'agent_01',
          resourceVersion: 'v3',
          scoreBand: 'low',
          currentScore: 22.0,
        ),
      ];

      final repo = Phase5MockCrmRepo(
        mockCustomers: [],
        mockLeads: mockLeads,
      );
      final provider = CrmProvider(crmRepository: repo);

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
            child: LeadsTab(
              crmProvider: provider,
              businessId: 'biz_01',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase5_leads.png');
      expect(File('docs/renders/phase5_leads.png').existsSync(), isTrue);
    });
  });
}
