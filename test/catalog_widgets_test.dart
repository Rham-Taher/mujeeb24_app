import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/catalog/catalog_repository.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/catalog_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_item_detail_screen.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_item_form_screen.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalog_items_screen.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalogs_screen.dart';
import 'package:mujeeb24_app/features/catalog/providers/catalog_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/dashboard_tab.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class FakeCatalogRepository extends CatalogRepository {
  List<Catalog> mockCatalogs;
  List<CatalogItem> mockItems;
  List<Variant> mockVariants;
  List<Offer> mockOffers;
  List<AttributeSchema> mockSchemas;
  CatalogEntityContract? mockContract;
  bool failEntityContract;
  bool failVariants;
  bool failOffers;
  CreateCatalogItemRequest? lastCreateItemRequest;

  bool listCatalogsCalled = false;
  bool createCatalogCalled = false;
  bool updateCatalogCalled = false;
  bool listItemsCalled = false;
  bool createItemCalled = false;
  bool updateItemCalled = false;
  bool listVariantsCalled = false;
  bool createVariantCalled = false;
  bool updateVariantCalled = false;
  bool listOffersCalled = false;
  bool createOfferCalled = false;
  bool updateOfferCalled = false;

  FakeCatalogRepository({
    this.mockCatalogs = const [],
    this.mockItems = const [],
    this.mockVariants = const [],
    this.mockOffers = const [],
    this.mockSchemas = const [],
    this.mockContract,
    this.failEntityContract = false,
    this.failVariants = false,
    this.failOffers = false,
  }) : super(apiClient: ApiClient(baseUrl: 'https://mock.local'));

  @override
  Future<CatalogPage> listCatalogs({
    required String businessId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    listCatalogsCalled = true;
    var filtered = List<Catalog>.from(mockCatalogs);
    if (status != null && status.isNotEmpty && status != 'all') {
      filtered = filtered.where((c) => c.status == status).toList();
    }
    return CatalogPage(items: filtered, hasMore: false);
  }

  @override
  Future<Catalog> createCatalog({
    required String businessId,
    required CreateCatalogRequest request,
    String? idempotencyKey,
  }) async {
    createCatalogCalled = true;
    final newCatalog = Catalog(
      id: 'cat_new_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      name: request.name,
      description: request.description,
      status: 'draft',
      resourceVersion: '1',
    );
    mockCatalogs = [newCatalog, ...mockCatalogs];
    return newCatalog;
  }

  @override
  Future<Catalog> getCatalog({
    required String businessId,
    required String catalogId,
  }) async {
    return mockCatalogs.firstWhere((c) => c.id == catalogId);
  }

  @override
  Future<Catalog> updateCatalog({
    required String businessId,
    required String catalogId,
    required UpdateCatalogRequest request,
    String? ifMatch,
  }) async {
    updateCatalogCalled = true;
    final index = mockCatalogs.indexWhere((c) => c.id == catalogId);
    final current = mockCatalogs[index];
    final updated = Catalog(
      id: catalogId,
      businessId: businessId,
      name: request.name ?? current.name,
      description: request.description ?? current.description,
      status: request.status ?? current.status,
      resourceVersion: '${(int.tryParse(current.resourceVersion) ?? 1) + 1}',
    );
    mockCatalogs[index] = updated;
    return updated;
  }

  @override
  Future<CatalogEntityContract> getCatalogEntityContract({required String businessId}) async {
    if (failEntityContract) throw StateError('entity-contract unavailable');
    return mockContract ?? CatalogEntityContract.defaults();
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
    listItemsCalled = true;
    var filtered = List<CatalogItem>.from(mockItems);
    if (status != null && status.isNotEmpty && status != 'all') {
      filtered = filtered.where((i) => i.status == status).toList();
    }
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((i) => i.name.contains(search)).toList();
    }
    return CatalogItemPage(items: filtered, hasMore: false);
  }

  @override
  Future<CatalogItem> createCatalogItem({
    required String businessId,
    required String catalogId,
    required CreateCatalogItemRequest request,
    String? idempotencyKey,
  }) async {
    createItemCalled = true;
    lastCreateItemRequest = request;
    final newItem = CatalogItem(
      id: 'item_new_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      catalogId: catalogId,
      itemType: request.itemType,
      name: request.name,
      shortDescription: request.shortDescription,
      longDescription: request.longDescription,
      status: 'draft',
      pricingMode: request.pricingMode,
      availabilityMode: request.availabilityMode,
      fulfillmentMode: request.fulfillmentMode,
      requiresConfirmation: request.requiresConfirmation,
      attributes: request.attributes,
      resourceVersion: '1',
    );
    mockItems = [newItem, ...mockItems];
    return newItem;
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
  Future<CatalogItem> updateCatalogItem({
    required String businessId,
    required String catalogId,
    required String itemId,
    required UpdateCatalogItemRequest request,
    String? ifMatch,
  }) async {
    updateItemCalled = true;
    final index = mockItems.indexWhere((i) => i.id == itemId);
    final current = mockItems[index];
    final updated = CatalogItem(
      id: itemId,
      businessId: businessId,
      catalogId: catalogId,
      itemType: request.itemType ?? current.itemType,
      name: request.name ?? current.name,
      shortDescription: request.shortDescription ?? current.shortDescription,
      longDescription: request.longDescription ?? current.longDescription,
      status: request.status ?? current.status,
      pricingMode: request.pricingMode ?? current.pricingMode,
      availabilityMode: request.availabilityMode ?? current.availabilityMode,
      fulfillmentMode: request.fulfillmentMode ?? current.fulfillmentMode,
      requiresConfirmation: request.requiresConfirmation ?? current.requiresConfirmation,
      attributes: request.attributes ?? current.attributes,
      resourceVersion: '${(int.tryParse(current.resourceVersion) ?? 1) + 1}',
    );
    mockItems[index] = updated;
    return updated;
  }

  @override
  Future<VariantPage> listVariants({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    listVariantsCalled = true;
    if (failVariants) throw StateError('variant list unavailable');
    return VariantPage(items: mockVariants, hasMore: false);
  }

  @override
  Future<Variant> createVariant({
    required String businessId,
    required String itemId,
    required CreateVariantRequest request,
    String? idempotencyKey,
  }) async {
    createVariantCalled = true;
    final newVar = Variant(
      id: 'var_new_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      catalogItemId: itemId,
      name: request.name,
      attributes: request.attributes,
      status: 'active',
      resourceVersion: '1',
    );
    mockVariants = [...mockVariants, newVar];
    return newVar;
  }

  @override
  Future<Variant> updateVariant({
    required String businessId,
    required String variantId,
    required UpdateVariantRequest request,
    String? ifMatch,
  }) async {
    updateVariantCalled = true;
    final index = mockVariants.indexWhere((v) => v.id == variantId);
    final current = mockVariants[index];
    final updated = Variant(
      id: variantId,
      businessId: businessId,
      catalogItemId: current.catalogItemId,
      name: request.name ?? current.name,
      attributes: request.attributes ?? current.attributes,
      status: request.status ?? current.status,
      resourceVersion: '${(int.tryParse(current.resourceVersion) ?? 1) + 1}',
    );
    mockVariants[index] = updated;
    return updated;
  }

  @override
  Future<OfferPage> listOffers({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    listOffersCalled = true;
    if (failOffers) throw StateError('offer list unavailable');
    return OfferPage(items: mockOffers, hasMore: false);
  }

  @override
  Future<Offer> createOffer({
    required String businessId,
    required String itemId,
    required CreateOfferRequest request,
    String? idempotencyKey,
  }) async {
    createOfferCalled = true;
    final newOffer = Offer(
      id: 'off_new_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      catalogItemId: itemId,
      variantId: request.variantId,
      name: request.name,
      pricingMode: request.pricingMode,
      amount: request.amount,
      currency: request.currency ?? 'SAR',
      priceVerificationStatus: 'unverified',
      availabilityMode: request.availabilityMode,
      fulfillmentMode: request.fulfillmentMode,
      availabilityStatus: request.availabilityStatus,
      status: request.status ?? 'active',
      resourceVersion: '1',
    );
    mockOffers = [...mockOffers, newOffer];
    return newOffer;
  }

  @override
  Future<Offer> updateOffer({
    required String businessId,
    required String offerId,
    required UpdateOfferRequest request,
    String? ifMatch,
  }) async {
    updateOfferCalled = true;
    final index = mockOffers.indexWhere((o) => o.id == offerId);
    final current = mockOffers[index];
    final updated = Offer(
      id: offerId,
      businessId: businessId,
      catalogItemId: current.catalogItemId,
      name: request.name ?? current.name,
      pricingMode: current.pricingMode,
      amount: request.amount ?? current.amount,
      currency: current.currency,
      priceVerificationStatus: current.priceVerificationStatus,
      availabilityMode: current.availabilityMode,
      fulfillmentMode: current.fulfillmentMode,
      availabilityStatus: request.availabilityStatus ?? current.availabilityStatus,
      status: request.status ?? current.status,
      resourceVersion: '${(int.tryParse(current.resourceVersion) ?? 1) + 1}',
    );
    mockOffers[index] = updated;
    return updated;
  }

  @override
  Future<List<AttributeSchema>> listAttributeSchemas({
    required String businessId,
    String? name,
    int? version,
  }) async {
    return mockSchemas;
  }

  @override
  Future<AttributeSchema> getAttributeSchema({
    required String businessId,
    required String schemaId,
  }) async {
    return mockSchemas.firstWhere((s) => s.id == schemaId);
  }
}

class FakeMerchantRepository extends MerchantRepository {
  DashboardOverview? mockOverview;
  FakeMerchantRepository({this.mockOverview}) : super(apiClient: ApiClient());

  @override
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    return mockOverview ??
        const DashboardOverview(
          openConversations: 10,
          waitingHuman: 2,
          newCustomers: 20,
          newLeads: 5,
          transactionsNeedingReview: 1,
          connections: {'واتساب': 5},
        );
  }
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ar'), Locale('en')],
    locale: const Locale('ar'),
    home: child,
  );
}

void main() {
  const testBusinessId = 'b1111111-1111-1111-1111-111111111111';
  const testCatalogId = 'c2222222-2222-2222-2222-222222222222';
  const testItemId = 'i3333333-3333-3333-3333-333333333333';

  final sampleCatalog = Catalog(
    id: testCatalogId,
    businessId: testBusinessId,
    name: 'كتالوج الصيف',
    description: 'منتجات موسم الصيف',
    status: 'active',
    resourceVersion: '1',
  );

  final sampleItem = CatalogItem(
    id: testItemId,
    businessId: testBusinessId,
    catalogId: testCatalogId,
    itemType: 'physical_good',
    name: 'قميص صيفي قطني',
    shortDescription: 'قميص قطني مريح',
    longDescription: 'قميص قطني مريح عالي الجودة متوفر بعدة ألوان',
    status: 'active',
    pricingMode: 'fixed',
    availabilityMode: 'stock',
    fulfillmentMode: 'delivery',
    requiresConfirmation: false,
    attributes: {'fabric': 'cotton', 'origin': 'local'},
    resourceVersion: '1',
  );

  final sampleVariant = Variant(
    id: 'var_01',
    businessId: testBusinessId,
    catalogItemId: testItemId,
    name: 'مقاس كبير - أزرق',
    attributes: {'size': 'XL', 'color': 'blue'},
    status: 'active',
    resourceVersion: '1',
  );

  final sampleOffer = Offer(
    id: 'off_01',
    businessId: testBusinessId,
    catalogItemId: testItemId,
    name: 'خصم الشراء المبكر',
    pricingMode: 'fixed',
    amount: 85.0,
    currency: 'SAR',
    priceVerificationStatus: 'verified',
    availabilityMode: 'stock',
    fulfillmentMode: 'delivery',
    availabilityStatus: 'available',
    status: 'active',
    resourceVersion: '1',
  );

  group('Phase 5 CatalogsScreen Widget Tests', () {
    testWidgets('Renders catalogs list, filters, and cards correctly', (tester) async {
      final fakeRepo = FakeCatalogRepository(mockCatalogs: [sampleCatalog]);
      final provider = CatalogProvider(catalogRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        CatalogsScreen(catalogProvider: provider, businessId: testBusinessId),
      ));
      await tester.pumpAndSettle();

      expect(find.text('كتالوج الصيف'), findsOneWidget);
      expect(find.text('منتجات موسم الصيف'), findsOneWidget);
      expect(find.text('كافة الكتالوجات'), findsOneWidget);
      expect(find.text('نشط'), findsWidgets);
      expect(fakeRepo.listCatalogsCalled, isTrue);
    });

    testWidgets('Opens create catalog dialog and creates a new catalog', (tester) async {
      final fakeRepo = FakeCatalogRepository(mockCatalogs: []);
      final provider = CatalogProvider(catalogRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        CatalogsScreen(catalogProvider: provider, businessId: testBusinessId),
      ));
      await tester.pumpAndSettle();

      // Tap on create button
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('إنشاء كتالوج جديد'), findsWidgets);

      // Enter catalog name
      final nameField = find.widgetWithText(TextFormField, 'اسم الكتالوج *');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'كتالوج العطور');

      // Submit via the dialog action button
      final dialogCreateBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'إنشاء كتالوج جديد'),
      );
      expect(dialogCreateBtn, findsOneWidget);
      await tester.tap(dialogCreateBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.createCatalogCalled, isTrue);
      expect(find.text('كتالوج العطور'), findsOneWidget);
    });
  });

  group('Phase 5 CatalogItemsScreen Widget Tests', () {
    testWidgets('Renders items list, chips, and allows search filtering', (tester) async {
      final fakeRepo = FakeCatalogRepository(
        mockCatalogs: [sampleCatalog],
        mockItems: [sampleItem],
      );
      final provider = CatalogProvider(catalogRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        CatalogItemsScreen(
          catalogProvider: provider,
          businessId: testBusinessId,
          catalog: sampleCatalog,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('قميص صيفي قطني'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(fakeRepo.listItemsCalled, isTrue);
    });
  });

  group('Phase 5 CatalogItemFormScreen Widget Tests', () {
    testWidgets('Renders item creation form with validation', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fakeRepo = FakeCatalogRepository(
        mockCatalogs: [sampleCatalog],
        mockItems: [],
      );
      final provider = CatalogProvider(catalogRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        CatalogItemFormScreen(
          catalogProvider: provider,
          businessId: testBusinessId,
          catalogId: testCatalogId,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('إضافة عنصر / منتج'), findsOneWidget);

      // Guided creation: no write until all three stages finish.
      final nextButton = find.widgetWithText(FilledButton, 'متابعة');
      // The merchant's next action stays pinned above the system navigation bar.
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(fakeRepo.createItemCalled, isFalse);

      final nameField = find.widgetWithText(TextFormField, 'اسم البند *');
      await tester.dragUntilVisible(
        nameField,
        find.byType(ListView),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      await tester.enterText(nameField, 'ساعة فاخرة');
      // The default choice is the human-readable 'منتج' -> API 'product'.
      expect(find.text('ما الذي تقدمه؟'), findsWidgets);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Item-only draft is a supported option; no invented price or availability.
      final skipOffer = find.text('حفظ السعر والتوفر الآن');
      await tester.dragUntilVisible(
        skipOffer,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(skipOffer);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.createItemCalled, isFalse);
      final saveButton = find.widgetWithText(FilledButton, 'حفظ المنتج');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.createItemCalled, isTrue);
    });
  });

  group('Independent product, variant and offer loading', () {
    test('product details remain accessible if variant/offer endpoints fail', () async {
      final repo = FakeCatalogRepository(
        mockItems: [sampleItem],
        failVariants: true,
        failOffers: true,
      );
      final provider = CatalogProvider(catalogRepository: repo);
      await provider.fetchItemDetail(testBusinessId, testCatalogId, testItemId);
      expect(provider.selectedItem?.id, testItemId);
      expect(provider.itemDetailError, isNull);
      expect(provider.variantsError, contains('متغيرات'));
      expect(provider.offersError, contains('أسعار'));
      expect(provider.variants, isEmpty);
      expect(provider.offers, isEmpty);

      repo.failVariants = false;
      repo.failOffers = false;
      repo.mockVariants = [sampleVariant];
      await provider.refreshVariants(testBusinessId, testItemId);
      await provider.refreshOffers(testBusinessId, testItemId);
      expect(provider.selectedItem?.id, testItemId);
      expect(provider.variantsError, isNull);
      expect(provider.offersError, isNull);
      expect(provider.variants.length, 1);
    });
  });

  group('Catalog draft when pricing contract is unavailable', () {
    testWidgets('merchant can save without price and add variants afterward',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repo = FakeCatalogRepository(
        mockCatalogs: [sampleCatalog],
        failEntityContract: true,
      );
      final provider = CatalogProvider(catalogRepository: repo);
      await tester.pumpWidget(createTestApp(
        CatalogItemFormScreen(
          catalogProvider: provider,
          businessId: testBusinessId,
          catalogId: testCatalogId,
        ),
      ));
      await tester.pumpAndSettle();
      final nameField = find.widgetWithText(TextFormField, 'اسم البند *');
      await tester.enterText(nameField, 'عطر فاخر');
      await tester.tap(find.widgetWithText(FilledButton, 'متابعة'));
      await tester.pumpAndSettle();

      expect(provider.hasLoadedContract, isFalse);
      expect(find.text('تعذر تحميل خيارات السعر والتوفر'), findsOneWidget);
      expect(find.byKey(const Key('catalog_skip_pricing_draft')), findsOneWidget);
      expect(repo.createItemCalled, isFalse);

      // A missing pricing-label endpoint cannot force a fake price or stock.
      await tester.tap(find.byKey(const Key('catalog_skip_pricing_draft')));
      await tester.pumpAndSettle();
      expect(find.text('التسعير: سيُحدد لاحقًا'), findsOneWidget);
      expect(find.text('السعر والتوفر سيُضافان لاحقًا'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ المنتج'));
      await tester.pumpAndSettle();

      expect(repo.createItemCalled, isTrue);
      final saved = repo.lastCreateItemRequest!;
      expect(saved.name, 'عطر فاخر');
      expect(saved.initialOffer, isNull);
      expect(saved.pricingMode, 'quote_required');
      expect(saved.availabilityMode, 'unknown');
      expect(saved.fulfillmentMode, 'manual');
    });

    testWidgets('newly created item shows optional variants as final step',
        (tester) async {
      final repo = FakeCatalogRepository(
        mockCatalogs: [sampleCatalog],
        mockItems: [sampleItem],
      );
      final provider = CatalogProvider(catalogRepository: repo);
      await tester.pumpWidget(createTestApp(
        CatalogItemDetailScreen(
          catalogProvider: provider,
          businessId: testBusinessId,
          catalogId: testCatalogId,
          itemId: sampleItem.id,
          initialTabIndex: 1,
          justCreated: true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('تم حفظ المنتج كمسودة'), findsOneWidget);
      expect(find.text('إنهاء الآن'), findsOneWidget);
      expect(find.text('إضافة متغير'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 5 CatalogItemDetailScreen Widget Tests', () {
    testWidgets('Displays 3 tabs and switches to Variants and Offers tabs', (tester) async {
      final fakeRepo = FakeCatalogRepository(
        mockCatalogs: [sampleCatalog],
        mockItems: [sampleItem],
        mockVariants: [sampleVariant],
        mockOffers: [sampleOffer],
      );
      final provider = CatalogProvider(catalogRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        CatalogItemDetailScreen(
          catalogProvider: provider,
          businessId: testBusinessId,
          catalogId: testCatalogId,
          itemId: testItemId,
        ),
      ));
      await tester.pumpAndSettle();

      // Check overview tab
      expect(find.text('نظرة عامة'), findsOneWidget);
      expect(find.text('المتغيرات (1)'), findsOneWidget);
      expect(find.text('العروض والأسعار (1)'), findsOneWidget);
      expect(find.text('قميص صيفي قطني'), findsWidgets);

      // Switch to Variants tab
      await tester.tap(find.text('المتغيرات (1)'));
      await tester.pumpAndSettle();
      expect(find.text('مقاس كبير - أزرق'), findsOneWidget);

      // Switch to Offers tab
      await tester.tap(find.text('العروض والأسعار (1)'));
      await tester.pumpAndSettle();
      expect(find.text('خصم الشراء المبكر'), findsOneWidget);
    });
  });

  group('Phase 5 Dashboard Integration Widget Tests', () {
    testWidgets('Dashboard renders Catalogs card and triggers navigation', (tester) async {
      var navigatedToCatalogs = false;
      final merchantRepo = FakeMerchantRepository(
        mockOverview: const DashboardOverview(
          openConversations: 10,
          waitingHuman: 2,
          newCustomers: 20,
          newLeads: 5,
          transactionsNeedingReview: 1,
          connections: {'واتساب': 5},
        ),
      );
      final merchantProvider = MerchantProvider(merchantRepository: merchantRepo);

      const business = Business(
        id: testBusinessId,
        name: 'متجر النجاح',
        slug: 'success-store',
        status: 'active',
      );

      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: DashboardTab(
            merchantProvider: merchantProvider,
            currentBusiness: business,
            onNavigateToInbox: () {},
            onNavigateToCatalogs: () {
              navigatedToCatalogs = true;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final catalogCard = find.text('الكتالوج والمنتجات');
      await tester.dragUntilVisible(
        catalogCard,
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(catalogCard, findsOneWidget);

      await tester.tap(catalogCard);
      await tester.pumpAndSettle();

      expect(navigatedToCatalogs, isTrue);
    });
  });
}
