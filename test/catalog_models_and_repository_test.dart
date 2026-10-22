import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/catalog/catalog_repository.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/models/catalog_models.dart';

void main() {
  const testBusinessId = 'b1111111-1111-1111-1111-111111111111';
  const testCatalogId = 'c2222222-2222-2222-2222-222222222222';
  const testItemId = 'i3333333-3333-3333-3333-333333333333';
  const testVariantId = 'v4444444-4444-4444-4444-444444444444';
  const testOfferId = 'o5555555-5555-5555-5555-555555555555';
  const testSchemaId = 's6666666-6666-6666-6666-666666666666';

  group('Phase 5 Catalog Models Unit Tests', () {
    test('Catalog parses from and converts to JSON correctly', () {
      final json = {
        'id': testCatalogId,
        'business_id': testBusinessId,
        'name': 'كتالوج المنتجات الرئيسية',
        'description': 'كتالوج المتجر العام',
        'status': 'active',
        'resource_version': '3',
      };

      final catalog = Catalog.fromJson(json);
      expect(catalog.id, testCatalogId);
      expect(catalog.businessId, testBusinessId);
      expect(catalog.name, 'كتالوج المنتجات الرئيسية');
      expect(catalog.description, 'كتالوج المتجر العام');
      expect(catalog.status, 'active');
      expect(catalog.resourceVersion, '3');
      expect(catalog.isActive, isTrue);
      expect(catalog.isArchived, isFalse);

      final serialized = catalog.toJson();
      expect(serialized['id'], testCatalogId);
      expect(serialized['name'], 'كتالوج المنتجات الرئيسية');
      expect(serialized['resource_version'], '3');
    });

    test('Catalog item parses from and converts to JSON with full enum fields', () {
      final json = {
        'id': testItemId,
        'business_id': testBusinessId,
        'catalog_id': testCatalogId,
        'item_type': 'physical_good',
        'name': 'قهوة مختصة كولومبية',
        'short_description': 'حبوب قهوة كولومبية فاخرة',
        'long_description': 'حبوب قهوة كولومبية فاخرة مغسولة ومعالجة بعناية',
        'status': 'active',
        'pricing_mode': 'fixed',
        'availability_mode': 'stock',
        'fulfillment_mode': 'delivery',
        'requires_confirmation': false,
        'attribute_schema_id': testSchemaId,
        'attribute_schema_version': 1,
        'attributes': {'roast_level': 'medium', 'weight_g': 250},
        'resource_version': '2',
      };

      final item = CatalogItem.fromJson(json);
      expect(item.id, testItemId);
      expect(item.name, 'قهوة مختصة كولومبية');
      expect(item.pricingMode, 'fixed');
      expect(item.availabilityMode, 'stock');
      expect(item.fulfillmentMode, 'delivery');
      expect(item.attributes['roast_level'], 'medium');
      expect(item.resourceVersion, '2');
      expect(item.isActive, isTrue);

      final serialized = item.toJson();
      expect(serialized['name'], 'قهوة مختصة كولومبية');
      expect(serialized['pricing_mode'], 'fixed');
      expect(serialized['availability_mode'], 'stock');
    });

    test('Variant parses from and converts to JSON correctly', () {
      final json = {
        'id': testVariantId,
        'business_id': testBusinessId,
        'catalog_item_id': testItemId,
        'name': 'كيس 1 كجم',
        'attributes': {'weight_g': 1000},
        'status': 'active',
        'resource_version': '1',
      };

      final variant = Variant.fromJson(json);
      expect(variant.id, testVariantId);
      expect(variant.businessId, testBusinessId);
      expect(variant.catalogItemId, testItemId);
      expect(variant.name, 'كيس 1 كجم');
      expect(variant.attributes['weight_g'], 1000);
      expect(variant.isActive, isTrue);

      final serialized = variant.toJson();
      expect(serialized['name'], 'كيس 1 كجم');
      expect(serialized['resource_version'], '1');
    });

    test('Offer parses from and converts to JSON correctly', () {
      final json = {
        'id': testOfferId,
        'business_id': testBusinessId,
        'catalog_item_id': testItemId,
        'name': 'عرض يوم التأسيس 20%',
        'pricing_mode': 'fixed',
        'amount': 52.4,
        'currency': 'SAR',
        'price_verification_status': 'verified',
        'availability_mode': 'stock',
        'fulfillment_mode': 'delivery',
        'availability_status': 'available',
        'status': 'active',
        'resource_version': '4',
      };

      final offer = Offer.fromJson(json);
      expect(offer.id, testOfferId);
      expect(offer.amount, 52.4);
      expect(offer.currency, 'SAR');
      expect(offer.priceVerificationStatus, 'verified');
      expect(offer.isActive, isTrue);

      final serialized = offer.toJson();
      expect(serialized['amount'], 52.4);
      expect(serialized['name'], 'عرض يوم التأسيس 20%');
    });

    test('AttributeSchema parses correctly with AttributeDefinitions', () {
      final json = {
        'id': testSchemaId,
        'business_id': testBusinessId,
        'name': 'سمات المنتجات الغذائية',
        'item_type': 'physical_good',
        'version': 1,
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
        'definitions': [
          {
            'id': 'def_1',
            'key': 'roast_level',
            'label': 'درجة التحميص',
            'data_type': 'text',
            'required': true,
          },
          {
            'id': 'def_2',
            'key': 'weight_g',
            'label': 'الوزن بالجرام',
            'data_type': 'number',
            'required': false,
          }
        ],
      };

      final schema = AttributeSchema.fromJson(json);
      expect(schema.id, testSchemaId);
      expect(schema.name, 'سمات المنتجات الغذائية');
      expect(schema.definitions.length, 2);
      expect(schema.definitions[0].key, 'roast_level');
      expect(schema.definitions[0].required, isTrue);
      expect(schema.definitions[1].key, 'weight_g');
      expect(schema.definitions[1].required, isFalse);

      final serialized = schema.toJson();
      expect(serialized['name'], 'سمات المنتجات الغذائية');
      expect(serialized['definitions'].length, 2);
    });

    test('CatalogEntityContract returns defaults and translates labels', () {
      final contract = CatalogEntityContract.defaults();
      expect(contract.labelFor('pricing_mode', 'fixed'), 'السعر ثابت ومحدد في العرض');
      expect(contract.labelFor('availability_status', 'available'), 'متاح حاليًا');
      expect(contract.labelFor('availability_status', 'requires_check'), 'يتطلب فحصًا إضافيًا');
      expect(contract.labelFor('fulfillment_mode', 'delivery'), 'تسليم مادي / توصيل وشحن');
      expect(contract.labelFor('status', 'archived'), 'مؤرشف');
      expect(contract.labelFor('unknown_category', 'some_code'), 'some_code');
    });

    test('CatalogPage, CatalogItemPage, VariantPage, OfferPage parse pagination properly', () {
      final catalogPageJson = {
        'items': [
          {
            'id': testCatalogId,
            'business_id': testBusinessId,
            'name': 'كتالوج 1',
            'status': 'active',
            'resource_version': '1',
          }
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };
      final catPage = CatalogPage.fromJson(catalogPageJson);
      expect(catPage.items.length, 1);

      final itemPageJson = {
        'items': [
          {
            'id': testItemId,
            'business_id': testBusinessId,
            'catalog_id': testCatalogId,
            'item_type': 'physical_good',
            'name': 'منتج 1',
            'status': 'active',
            'pricing_mode': 'fixed',
            'availability_mode': 'stock',
            'fulfillment_mode': 'delivery',
            'resource_version': '1',
          }
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };
      final itemPage = CatalogItemPage.fromJson(itemPageJson);
      expect(itemPage.items.length, 1);

      final varPageJson = {
        'items': [
          {
            'id': testVariantId,
            'business_id': testBusinessId,
            'catalog_item_id': testItemId,
            'name': 'متغير 1',
            'status': 'active',
            'resource_version': '1',
          }
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };
      final varPage = VariantPage.fromJson(varPageJson);
      expect(varPage.items.length, 1);

      final offerPageJson = {
        'items': [
          {
            'id': testOfferId,
            'business_id': testBusinessId,
            'catalog_item_id': testItemId,
            'name': 'عرض 1',
            'pricing_mode': 'fixed',
            'amount': 99.0,
            'price_verification_status': 'verified',
            'availability_mode': 'stock',
            'fulfillment_mode': 'delivery',
            'availability_status': 'available',
            'status': 'active',
            'resource_version': '1',
          }
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };
      final offPage = OfferPage.fromJson(offerPageJson);
      expect(offPage.items.length, 1);
    });
  });

  group('Phase 5 Catalog Repository Integration with MockClient', () {
    test('listCatalogs sends proper query parameters and parses CatalogPage', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalogs');
        expect(request.url.queryParameters['status'], 'active');
        expect(request.url.queryParameters['limit'], '10');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': testCatalogId,
                'business_id': testBusinessId,
                'name': 'كتالوج الصيف',
                'status': 'active',
                'resource_version': '1',
              }
            ],
            'total': 1,
            'limit': 10,
            'offset': 0,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final page = await repo.listCatalogs(
        businessId: testBusinessId,
        status: 'active',
        limit: 10,
      );

      expect(page.items.length, 1);
      expect(page.items.first.name, 'كتالوج الصيف');
    });

    test('createCatalog sends POST with Idempotency-Key and parses Catalog', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalogs');
        expect(request.headers.containsKey('Idempotency-Key'), isTrue);

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'كتالوج جديد');

        return http.Response(
          jsonEncode({
            'id': testCatalogId,
            'business_id': testBusinessId,
            'name': 'كتالوج جديد',
            'status': 'draft',
            'resource_version': '1',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final catalog = await repo.createCatalog(
        businessId: testBusinessId,
        request: const CreateCatalogRequest(name: 'كتالوج جديد'),
      );

      expect(catalog.id, testCatalogId);
      expect(catalog.name, 'كتالوج جديد');
    });

    test('updateCatalog sends PATCH with If-Match resource_version', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalogs/$testCatalogId');
        expect(request.headers['If-Match'], '1');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'كتالوج معدل');
        expect(body['status'], 'active');

        return http.Response(
          jsonEncode({
            'id': testCatalogId,
            'business_id': testBusinessId,
            'name': 'كتالوج معدل',
            'status': 'active',
            'resource_version': '2',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final catalog = await repo.updateCatalog(
        businessId: testBusinessId,
        catalogId: testCatalogId,
        ifMatch: '1',
        request: const UpdateCatalogRequest(name: 'كتالوج معدل', status: 'active'),
      );

      expect(catalog.resourceVersion, '2');
      expect(catalog.name, 'كتالوج معدل');
    });

    test('getCatalogEntityContract fetches dynamic contract', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalogs/entity-contract');

        return http.Response(
          jsonEncode({
            'enums': {
              'pricing_mode': [
                {'code': 'fixed', 'label': 'سعر ثابت خادم'},
                {'code': 'dynamic', 'label': 'سعر متغير خادم'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final contract = await repo.getCatalogEntityContract(businessId: testBusinessId);
      expect(contract.labelFor('pricing_mode', 'fixed'), 'سعر ثابت خادم');
      expect(contract.labelFor('pricing_mode', 'dynamic'), 'سعر متغير خادم');
    });

    test('listCatalogItems sends query parameters and parses CatalogItemPage', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalogs/$testCatalogId/items');
        expect(request.url.queryParameters['search'], 'ساعة');
        expect(request.url.queryParameters['status'], 'active');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': testItemId,
                'business_id': testBusinessId,
                'catalog_id': testCatalogId,
                'item_type': 'physical_good',
                'name': 'ساعة ذكية',
                'pricing_mode': 'fixed',
                'availability_mode': 'stock',
                'fulfillment_mode': 'pickup',
                'status': 'active',
                'resource_version': '1',
              }
            ],
            'total': 1,
            'limit': 20,
            'offset': 0,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final page = await repo.listCatalogItems(
        businessId: testBusinessId,
        catalogId: testCatalogId,
        search: 'ساعة',
        status: 'active',
      );

      expect(page.items.length, 1);
      expect(page.items.first.name, 'ساعة ذكية');
      expect(page.items.first.fulfillmentMode, 'pickup');
    });

    test('createCatalogItem and updateCatalogItem handle optimistic concurrency', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          return http.Response(
            jsonEncode({
              'id': testItemId,
              'business_id': testBusinessId,
              'catalog_id': testCatalogId,
              'item_type': 'service',
              'name': 'منتج جديد',
              'pricing_mode': 'starting_from',
              'availability_mode': 'schedule',
              'fulfillment_mode': 'appointment',
              'status': 'draft',
              'resource_version': '1',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'PATCH') {
          expect(request.headers['If-Match'], '1');
          return http.Response(
            jsonEncode({
              'id': testItemId,
              'business_id': testBusinessId,
              'catalog_id': testCatalogId,
              'item_type': 'service',
              'name': 'منتج معدل',
              'pricing_mode': 'starting_from',
              'availability_mode': 'schedule',
              'fulfillment_mode': 'appointment',
              'status': 'active',
              'resource_version': '2',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final created = await repo.createCatalogItem(
        businessId: testBusinessId,
        catalogId: testCatalogId,
        request: const CreateCatalogItemRequest(
          name: 'منتج جديد',
          itemType: 'service',
          pricingMode: 'starting_from',
          availabilityMode: 'schedule',
          fulfillmentMode: 'appointment',
        ),
      );
      expect(created.resourceVersion, '1');

      final updated = await repo.updateCatalogItem(
        businessId: testBusinessId,
        catalogId: testCatalogId,
        itemId: testItemId,
        ifMatch: '1',
        request: const UpdateCatalogItemRequest(
          name: 'منتج معدل',
          status: 'active',
        ),
      );
      expect(updated.resourceVersion, '2');
      expect(updated.name, 'منتج معدل');
    });

    test('listVariants, createVariant, updateVariant endpoints work properly', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': testVariantId,
                  'business_id': testBusinessId,
                  'catalog_item_id': testItemId,
                  'name': 'مقاس كبير',
                  'status': 'active',
                  'resource_version': '1',
                }
              ],
              'total': 1,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'POST') {
          expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalog-items/$testItemId/variants');
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          return http.Response(
            jsonEncode({
              'id': testVariantId,
              'business_id': testBusinessId,
              'catalog_item_id': testItemId,
              'name': 'مقاس صغير',
              'status': 'active',
              'resource_version': '1',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'PATCH') {
          expect(request.url.path, '/api/v1/businesses/$testBusinessId/variants/$testVariantId');
          expect(request.headers['If-Match'], '1');
          return http.Response(
            jsonEncode({
              'id': testVariantId,
              'business_id': testBusinessId,
              'catalog_item_id': testItemId,
              'name': 'مقاس صغير محدث',
              'status': 'inactive',
              'resource_version': '2',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final vars = await repo.listVariants(businessId: testBusinessId, itemId: testItemId);
      expect(vars.items.length, 1);

      final createdVar = await repo.createVariant(
        businessId: testBusinessId,
        itemId: testItemId,
        request: const CreateVariantRequest(name: 'مقاس صغير'),
      );
      expect(createdVar.name, 'مقاس صغير');

      final updatedVar = await repo.updateVariant(
        businessId: testBusinessId,
        variantId: testVariantId,
        ifMatch: '1',
        request: const UpdateVariantRequest(name: 'مقاس صغير محدث', status: 'inactive'),
      );
      expect(updatedVar.resourceVersion, '2');
      expect(updatedVar.status, 'inactive');
    });

    test('listOffers, createOffer, updateOffer endpoints work properly', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': testOfferId,
                  'business_id': testBusinessId,
                  'catalog_item_id': testItemId,
                  'name': 'عرض الجمعة',
                  'pricing_mode': 'fixed',
                  'amount': 99.0,
                  'price_verification_status': 'verified',
                  'availability_mode': 'stock',
                  'fulfillment_mode': 'delivery',
                  'availability_status': 'available',
                  'status': 'active',
                  'resource_version': '1',
                }
              ],
              'total': 1,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'POST') {
          expect(request.url.path, '/api/v1/businesses/$testBusinessId/catalog-items/$testItemId/offers');
          expect(request.headers.containsKey('Idempotency-Key'), isTrue);
          return http.Response(
            jsonEncode({
              'id': testOfferId,
              'business_id': testBusinessId,
              'catalog_item_id': testItemId,
              'name': 'عرض خاص',
              'pricing_mode': 'fixed',
              'amount': 80.0,
              'price_verification_status': 'unverified',
              'availability_mode': 'stock',
              'fulfillment_mode': 'delivery',
              'availability_status': 'available',
              'status': 'draft',
              'resource_version': '1',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'PATCH') {
          expect(request.url.path, '/api/v1/businesses/$testBusinessId/offers/$testOfferId');
          expect(request.headers['If-Match'], '1');
          return http.Response(
            jsonEncode({
              'id': testOfferId,
              'business_id': testBusinessId,
              'catalog_item_id': testItemId,
              'name': 'عرض خاص مفعل',
              'pricing_mode': 'fixed',
              'amount': 75.0,
              'price_verification_status': 'unverified',
              'availability_mode': 'stock',
              'fulfillment_mode': 'delivery',
              'availability_status': 'available',
              'status': 'active',
              'resource_version': '2',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final offers = await repo.listOffers(businessId: testBusinessId, itemId: testItemId);
      expect(offers.items.length, 1);

      final createdOff = await repo.createOffer(
        businessId: testBusinessId,
        itemId: testItemId,
        request: const CreateOfferRequest(
          name: 'عرض خاص',
          amount: 80.0,
          pricingMode: 'fixed',
          availabilityMode: 'stock',
          availabilityStatus: 'available',
          fulfillmentMode: 'delivery',
          status: 'draft',
        ),
      );
      expect(createdOff.amount, 80.0);

      final updatedOff = await repo.updateOffer(
        businessId: testBusinessId,
        offerId: testOfferId,
        ifMatch: '1',
        request: const UpdateOfferRequest(name: 'عرض خاص مفعل', amount: 75.0, status: 'active'),
      );
      expect(updatedOff.resourceVersion, '2');
      expect(updatedOff.amount, 75.0);
    });

    test('listAttributeSchemas and getAttributeSchema return definitions', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/attribute-schemas')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': testSchemaId,
                  'business_id': testBusinessId,
                  'name': 'مخطط الملابس',
                  'item_type': 'physical_good',
                  'version': 1,
                  'status': 'active',
                  'created_at': '2026-01-01T00:00:00Z',
                  'definitions': [],
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else {
          return http.Response(
            jsonEncode({
              'id': testSchemaId,
              'business_id': testBusinessId,
              'name': 'مخطط الملابس',
              'item_type': 'physical_good',
              'version': 1,
              'status': 'active',
              'created_at': '2026-01-01T00:00:00Z',
              'definitions': [
                {
                  'id': 'def_size',
                  'key': 'size',
                  'label': 'المقاس',
                  'data_type': 'text',
                  'required': true,
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      final schemas = await repo.listAttributeSchemas(businessId: testBusinessId);
      expect(schemas.length, 1);
      expect(schemas.first.name, 'مخطط الملابس');

      final detail = await repo.getAttributeSchema(businessId: testBusinessId, schemaId: testSchemaId);
      expect(detail.definitions.length, 1);
      expect(detail.definitions.first.key, 'size');
    });

    test('listAttributeSchemas loads cursor pages without omitting later Arabic templates', () async {
      var requests = 0;
      final mock = MockClient((request) async {
        requests++;
        expect(request.url.path,
          '/api/v1/businesses/$testBusinessId/attribute-schemas');
        expect(request.url.queryParameters['limit'], '50');
        final cursor = request.url.queryParameters['cursor'];
        final firstPage = cursor == null;
        if (!firstPage) expect(cursor, 'next-templates');
        return http.Response(jsonEncode({
          'items': [
            {
              'id': firstPage ? 'schema-one' : 'schema-two',
              'business_id': testBusinessId,
              'name': firstPage ? 'مواصفات الملابس' : 'مواصفات الهواتف',
              'version': 1,
              'definitions': [],
            }
          ],
          'pagination': {
            'has_more': firstPage,
            'next_cursor': firstPage ? 'next-templates' : null,
          },
        }), 200, headers: {'content-type': 'application/json'});
      });
      final repo = CatalogRepository(apiClient: ApiClient(client: mock));
      final templates = await repo.listAttributeSchemas(businessId: testBusinessId);
      expect(templates.map((schema) => schema.name),
        ['مواصفات الملابس', 'مواصفات الهواتف']);
      expect(requests, 2);
    });

    test('throws ApiErrorEnvelope on HTTP 412 Precondition Failed during concurrent update', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'CONFLICT_PRECONDITION_FAILED',
              'message': 'نسخة المورد أحدث على الخادم، يرجى إعادة التحديث',
              'retryable': false,
            },
            'request_id': 'req_conflict_99',
          }),
          412,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mock);
      final repo = CatalogRepository(apiClient: apiClient);

      expect(
        () => repo.updateCatalog(
          businessId: testBusinessId,
          catalogId: testCatalogId,
          ifMatch: '1',
          request: const UpdateCatalogRequest(name: 'تعديل ملغي'),
        ),
        throwsA(isA<ApiErrorEnvelope>().having((e) => e.statusCode, 'statusCode', 412)),
      );
    });
  });
}
