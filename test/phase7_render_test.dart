import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/catalog/catalog_repository.dart';
import 'package:mujeeb24_app/core/models/catalog_models.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_items_screen.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_item_detail_screen.dart';
import 'package:mujeeb24_app/features/catalog/providers/catalog_provider.dart';

class Phase7MockCatalogRepo extends CatalogRepository {
  final List<Catalog> mockCatalogs;
  final List<CatalogItem> mockItems;
  final List<Variant> mockVariants;
  final List<Offer> mockOffers;

  Phase7MockCatalogRepo({
    required this.mockCatalogs,
    required this.mockItems,
    this.mockVariants = const [],
    this.mockOffers = const [],
  }) : super(apiClient: ApiClient());

  @override
  Future<CatalogPage> listCatalogs({
    required String businessId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    return CatalogPage(items: mockCatalogs, hasMore: false);
  }

  @override
  Future<CatalogEntityContract> getCatalogEntityContract({required String businessId}) async {
    return CatalogEntityContract.defaults();
  }

  @override
  Future<CatalogItemPage> listCatalogItems({
    required String businessId,
    required String catalogId,
    String? status,
    String? search,
    String? cursor,
    int limit = 25,
  }) async {
    return CatalogItemPage(items: mockItems, hasMore: false);
  }

  @override
  Future<CatalogItem> getCatalogItem({
    required String businessId,
    required String catalogId,
    required String itemId,
  }) async {
    return mockItems.firstWhere((i) => i.id == itemId);
  }

  @override
  Future<VariantPage> listVariants({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    return VariantPage(items: mockVariants, hasMore: false);
  }

  @override
  Future<OfferPage> listOffers({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    return OfferPage(items: mockOffers, hasMore: false);
  }

  @override
  Future<List<AttributeSchema>> listAttributeSchemas({
    required String businessId,
    String? name,
    int? version,
  }) async {
    return [];
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
  final sampleCatalog = Catalog(
    id: 'cat_01',
    businessId: businessId,
    name: 'مجموعة العطور الفاخرة',
    description: 'تشكيلة العطور الشرقية والفرنسية الملكية',
    status: 'active',
    resourceVersion: '1',
  );

  final sampleItems = [
    CatalogItem(
      id: 'item_01',
      businessId: businessId,
      catalogId: sampleCatalog.id,
      itemType: 'product',
      name: 'عطر العود الملكي المعتق (100 مل)',
      shortDescription: 'خلاصة دهن العود الكمبودي والورد الطائفي الفاخر',
      longDescription: 'تركيبة عطرية استثنائية تمزج بين أصالة العود الشرقي وثبات يدوم لأكثر من 48 ساعة.',
      status: 'active',
      pricingMode: 'fixed',
      availabilityMode: 'stock',
      fulfillmentMode: 'delivery',
      requiresConfirmation: false,
      attributes: const {'النوع': 'عطر بخاخ', 'الحجم': '100 مل', 'التركيز': 'أو دو بارفيوم'},
      resourceVersion: '1',
    ),
    CatalogItem(
      id: 'item_02',
      businessId: businessId,
      catalogId: sampleCatalog.id,
      itemType: 'product',
      name: 'طقم إهداء العطور المؤسسية',
      shortDescription: 'باقة مخصصة للشركات والجهات تتضمن عطرين ومخلط ملكي',
      status: 'active',
      pricingMode: 'per_unit',
      availabilityMode: 'stock',
      fulfillmentMode: 'delivery',
      requiresConfirmation: true,
      attributes: const {'التغليف': 'صندوق خشبي فاخر', 'الحد الأدنى': '10 باقات'},
      resourceVersion: '1',
    ),
    CatalogItem(
      id: 'item_03',
      businessId: businessId,
      catalogId: sampleCatalog.id,
      itemType: 'service',
      name: 'استشارة تصميم العطور الخاصة',
      shortDescription: 'جلسة خاصة مع خبير العطور لتصميم بصمة عطرية حصرية',
      status: 'draft',
      pricingMode: 'quote_required',
      availabilityMode: 'appointment',
      fulfillmentMode: 'manual',
      requiresConfirmation: true,
      attributes: const {'المدة': 'ساعة واحدة', 'المكان': 'عن بُعد / حضوري'},
      resourceVersion: '1',
    ),
  ];

  final sampleVariants = [
    Variant(
      id: 'var_01',
      businessId: businessId,
      catalogItemId: 'item_01',
      name: 'حجم 100 مل - زجاجة سوداء كريستالية',
      attributes: const {'الحجم': '100 مل', 'اللون': 'أسود'},
      status: 'active',
      resourceVersion: '1',
    ),
    Variant(
      id: 'var_02',
      businessId: businessId,
      catalogItemId: 'item_01',
      name: 'حجم 50 مل - مناسب للسفر',
      attributes: const {'الحجم': '50 مل', 'اللون': 'فضي'},
      status: 'active',
      resourceVersion: '1',
    ),
  ];

  final sampleOffers = [
    Offer(
      id: 'off_01',
      businessId: businessId,
      catalogItemId: 'item_01',
      name: 'سعر البيع الأساسي',
      pricingMode: 'fixed',
      amount: 420.0,
      currency: 'SAR',
      priceVerificationStatus: 'verified',
      availabilityMode: 'stock',
      fulfillmentMode: 'delivery',
      availabilityStatus: 'available',
      status: 'active',
      resourceVersion: '1',
    ),
    Offer(
      id: 'off_02',
      businessId: businessId,
      catalogItemId: 'item_01',
      name: 'خصم الشراء بالجملة (3 قطع فأكثر)',
      pricingMode: 'fixed',
      amount: 360.0,
      currency: 'SAR',
      priceVerificationStatus: 'verified',
      availabilityMode: 'stock',
      fulfillmentMode: 'delivery',
      availabilityStatus: 'available',
      status: 'active',
      resourceVersion: '1',
    ),
  ];

  group('Phase 7 Visual Capture Tests', () {
    testWidgets('Capture CatalogItemsScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final repo = Phase7MockCatalogRepo(
        mockCatalogs: [sampleCatalog],
        mockItems: sampleItems,
        mockVariants: sampleVariants,
        mockOffers: sampleOffers,
      );
      final provider = CatalogProvider(catalogRepository: repo);

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
            home: CatalogItemsScreen(
              catalogProvider: provider,
              businessId: businessId,
              catalog: sampleCatalog,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await captureWidgetScreenshot(
        tester,
        key,
        'docs/renders/phase7_catalog.png',
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Capture CatalogItemDetailScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      final repo = Phase7MockCatalogRepo(
        mockCatalogs: [sampleCatalog],
        mockItems: sampleItems,
        mockVariants: sampleVariants,
        mockOffers: sampleOffers,
      );
      final provider = CatalogProvider(catalogRepository: repo);

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
            home: CatalogItemDetailScreen(
              catalogProvider: provider,
              businessId: businessId,
              catalogId: sampleCatalog.id,
              itemId: 'item_01',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await captureWidgetScreenshot(
        tester,
        key,
        'docs/renders/phase7_product_detail.png',
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
