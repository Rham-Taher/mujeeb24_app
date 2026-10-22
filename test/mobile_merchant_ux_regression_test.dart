import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_specification_input.dart';
import 'package:mujeeb24_app/features/catalog/presentation/merchant_editor_dialog.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class _FailingDashboardRepository extends MerchantRepository {
  bool fail = false;
  _FailingDashboardRepository() : super(apiClient: ApiClient());

  @override
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    if (fail) {
      throw ApiErrorEnvelope.fromRaw(
        code: 'INVALID_ACCESS_TOKEN',
        message: 'invalid access token',
        statusCode: 401,
        requestId: 'request-test',
      );
    }
    return const DashboardOverview(
      openConversations: 13, waitingHuman: 2,
      newCustomers: 3, newLeads: 0,
      transactionsNeedingReview: 0,
      connections: {'facebook': 1},
    );
  }
}

void main() {
  test('401 never exposes raw API text or stale dashboard metrics', () async {
    final fake = _FailingDashboardRepository();
    final provider = MerchantProvider(merchantRepository: fake);
    await provider.loadDashboardOverview('b1');
    expect(provider.dashboardOverview?.openConversations, 13);
    fake.fail = true;
    await provider.loadDashboardOverview('b1');
    expect(provider.dashboardRequiresLogin, isTrue);
    expect(provider.dashboardOverview, isNull);
    expect(provider.dashboardError, isNot(contains('invalid access token')));
    expect(provider.lastRequestId, 'request-test');
  });

  test('API policy notes do not leak into merchant pricing labels', () {
    expect(
      merchantCatalogOptionLabel('السعر لكل وحدة (amount + pricing_unit مطلوبان)'),
      'السعر لكل وحدة',
    );
    expect(merchantCatalogOptionLabel('سعر ثابت في العرض'),
      'سعر ثابت في العرض');
    expect(merchantItemTypeLabel('service'), 'خدمة');
  });

  for (final size in [
    const Size(320, 620),
    const Size(390, 844),
    const Size(640, 360),
  ]) {
    testWidgets('Offer and variant editors use a usable viewport at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        home: Builder(builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => MerchantEditorDialog(
                title: const Text('تعديل العرض'),
                content: SingleChildScrollView(child: Form(
                  child: Column(children: [
                    for (var i = 0; i < 12; i++)
                      Padding(padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'معلومة رقم ${i + 1}'))),
                  ]),
                )),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
                  FilledButton(onPressed: () {}, child: const Text('حفظ')),
                ],
              ),
            ),
            child: const Text('افتح التحرير'),
          )),
        )),
      ));
      await tester.tap(find.text('افتح التحرير'));
      await tester.pumpAndSettle();
      expect(find.text('تعديل العرض'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width < 600) {
        expect(find.byType(Dialog), findsWidgets);
      }
    });
  }
}
