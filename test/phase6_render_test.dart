import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/models/transaction_models.dart';
import 'package:mujeeb24_app/core/transactions/transaction_repository.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transactions_screen.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';

class Phase6MockTransactionRepo extends TransactionRepository {
  final List<CommercialTransaction> mockTransactions;
  final TransactionReview? mockReview;

  Phase6MockTransactionRepo({
    required this.mockTransactions,
    this.mockReview,
  }) : super(apiClient: ApiClient());

  @override
  Future<TransactionPage> listTransactions({
    required String businessId,
    String? state,
    String? transactionType,
    String? customerId,
    String? cursor,
    int limit = 25,
  }) async {
    var filtered = List<CommercialTransaction>.from(mockTransactions);
    if (state != null && state.isNotEmpty && state != 'all') {
      filtered = filtered.where((t) => t.state == state).toList();
    }
    if (transactionType != null &&
        transactionType.isNotEmpty &&
        transactionType != 'all') {
      filtered = filtered
          .where((t) => t.transactionType == transactionType)
          .toList();
    }
    return TransactionPage(items: filtered, hasMore: false);
  }

  @override
  Future<CommercialTransaction> getTransaction({
    required String businessId,
    required String transactionId,
  }) async {
    return mockTransactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => mockTransactions.first,
    );
  }

  @override
  Future<TransactionReview> getTransactionReview({
    required String businessId,
    required String transactionId,
  }) async {
    return mockReview ??
        const TransactionReview(
          required: true,
          status: 'pending',
          reasonCodes: ['high_value', 'b2b_transfer'],
          reviewerReference: 'finance_manager',
        );
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

  const businessId = 'b_test_01';

  final sampleTransactions = [
    CommercialTransaction(
      id: 'TRX-94820',
      businessId: businessId,
      customerId: 'مؤسسة البناء الحديث',
      leadId: 'LEAD-4829',
      transactionType: 'order',
      state: 'review',
      totalAmount: 18200.0,
      currency: 'SAR',
      lines: const [
        {
          'id': 'line_01',
          'catalog_item_id': 'CAT-GIFT-50',
          'item_name_snapshot': 'طلب توريد هدايا مكتبية وعطور مؤسسية',
          'quantity': 50.0,
          'unit_price_snapshot': 364.0,
          'currency': 'SAR',
        },
      ],
      schemaVersion: 1,
      resourceVersion: 'v2',
      createdAt: '2026-10-16T10:30:00Z',
      updatedAt: '2026-10-16T11:00:00Z',
    ),
    CommercialTransaction(
      id: 'DR-88210',
      businessId: businessId,
      customerId: 'سارة أحمد الكردي',
      transactionType: 'order',
      state: 'draft',
      totalAmount: 420.0,
      currency: 'SAR',
      lines: const [
        {
          'id': 'line_02',
          'catalog_item_id': 'CAT-OUD-ROYAL',
          'item_name_snapshot': 'عطر العود الملكي المعتق (100 مل)',
          'quantity': 1.0,
          'unit_price_snapshot': 420.0,
          'currency': 'SAR',
        },
      ],
      schemaVersion: 1,
      resourceVersion: 'v1',
      createdAt: '2026-10-16T09:45:00Z',
      updatedAt: '2026-10-16T09:45:00Z',
    ),
    CommercialTransaction(
      id: 'INV-73190',
      businessId: businessId,
      customerId: 'فهد القحطاني',
      transactionType: 'invoice',
      state: 'confirmed',
      totalAmount: 1200.0,
      currency: 'SAR',
      lines: const [
        {
          'id': 'line_03',
          'catalog_item_id': 'CAT-SET-VIP',
          'item_name_snapshot': 'طقم عطور شرقية فاخرة',
          'quantity': 2.0,
          'unit_price_snapshot': 600.0,
          'currency': 'SAR',
        },
      ],
      schemaVersion: 1,
      resourceVersion: 'v3',
      createdAt: '2026-10-15T16:20:00Z',
      updatedAt: '2026-10-15T17:00:00Z',
    ),
    CommercialTransaction(
      id: 'QUO-44120',
      businessId: businessId,
      customerId: 'عبدالله بن فهد الشمري',
      transactionType: 'quote',
      state: 'cancelled',
      totalAmount: 350.0,
      currency: 'SAR',
      lines: const [
        {
          'id': 'line_04',
          'catalog_item_id': 'CAT-BAG-LTH',
          'item_name_snapshot': 'حقيبة جلدية فاخرة',
          'quantity': 1.0,
          'unit_price_snapshot': 350.0,
          'currency': 'SAR',
        },
      ],
      schemaVersion: 1,
      resourceVersion: 'v2',
      createdAt: '2026-10-14T11:15:00Z',
      updatedAt: '2026-10-14T12:00:00Z',
    ),
  ];

  group('Phase 6 Visual Capture Tests', () {
    testWidgets('Capture TransactionsScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final repo = Phase6MockTransactionRepo(
        mockTransactions: sampleTransactions,
      );
      final provider = TransactionProvider(transactionRepository: repo);

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF005BB3),
                primary: const Color(0xFF005BB3),
              ),
              fontFamily: 'Roboto',
            ),
            home: TransactionsScreen(
              transactionProvider: provider,
              businessId: businessId,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await captureWidgetScreenshot(
        tester,
        key,
        'docs/renders/phase6_orders.png',
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Capture TransactionDetailScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final repo = Phase6MockTransactionRepo(
        mockTransactions: sampleTransactions,
        mockReview: const TransactionReview(
          required: true,
          status: 'pending',
          reasonCodes: ['high_value', 'b2b_transfer'],
          reviewerReference: 'finance_manager',
        ),
      );
      final provider = TransactionProvider(transactionRepository: repo);

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF005BB3),
                primary: const Color(0xFF005BB3),
              ),
              fontFamily: 'Roboto',
            ),
            home: TransactionDetailScreen(
              transactionProvider: provider,
              businessId: businessId,
              transactionId: 'TRX-94820',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await captureWidgetScreenshot(
        tester,
        key,
        'docs/renders/phase6_order_detail.png',
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
