import '../api/api_client.dart';
import '../models/catalog_models.dart';

/// Repository for handling all Catalog, Items, Variants, Offers, and
/// AttributeSchemas API operations in Mujeeb24.
class CatalogRepository {
  final ApiClient apiClient;

  CatalogRepository({required this.apiClient});

  String _generateIdempotencyKey(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Map<String, dynamic> _extractDataMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return response;
    } else if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    throw StateError('Unexpected response format: $response');
  }

  List<dynamic> _extractDataList(dynamic response) {
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['items'] is List) return response['items'] as List;
    } else if (response is List) {
      return response;
    }
    return const [];
  }

  // ==========================================
  // Catalogs
  // ==========================================

  /// Lists all catalogs for a business.
  /// `GET /businesses/{business_id}/catalogs`
  Future<CatalogPage> listCatalogs({
    required String businessId,
    String? status,
    String? cursor,
    int limit = 25,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await apiClient.get(
      '/businesses/$businessId/catalogs',
      queryParameters: queryParams,
    );

    final List<Catalog> items = [];
    for (final item in _extractDataList(response)) {
      if (item is Map<String, dynamic>) {
        items.add(Catalog.fromJson(item));
      } else if (item is Map) {
        items.add(Catalog.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final pagination = response is Map ? response['pagination'] : null;
    final hasMore = pagination is Map && pagination['has_more'] == true;
    final nextCursor = pagination is Map ? pagination['next_cursor']?.toString() : null;
    final requestId = response is Map ? response['request_id']?.toString() : null;

    return CatalogPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
      requestId: requestId,
    );
  }

  /// Creates a new catalog.
  /// `POST /businesses/{business_id}/catalogs`
  Future<Catalog> createCatalog({
    required String businessId,
    required CreateCatalogRequest request,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('catalog'),
    };

    final response = await apiClient.post(
      '/businesses/$businessId/catalogs',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Catalog.fromJson(_extractDataMap(response));
  }

  /// Retrieves a specific catalog by ID.
  /// `GET /businesses/{business_id}/catalogs/{catalog_id}`
  Future<Catalog> getCatalog({
    required String businessId,
    required String catalogId,
  }) async {
    final response = await apiClient.get(
      '/businesses/$businessId/catalogs/$catalogId',
    );

    return Catalog.fromJson(_extractDataMap(response));
  }

  /// Updates an existing catalog with optimistic concurrency control.
  /// `PATCH /businesses/{business_id}/catalogs/{catalog_id}`
  Future<Catalog> updateCatalog({
    required String businessId,
    required String catalogId,
    required UpdateCatalogRequest request,
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': _generateIdempotencyKey('catalog_update'),
      if (ifMatch != null && ifMatch.isNotEmpty) 'If-Match': ifMatch,
    };

    final response = await apiClient.patch(
      '/businesses/$businessId/catalogs/$catalogId',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Catalog.fromJson(_extractDataMap(response));
  }

  /// Retrieves the dynamic Catalog Entity Contract with Arabic label dictionaries.
  /// `GET /businesses/{business_id}/catalogs/entity-contract`
  Future<CatalogEntityContract> getCatalogEntityContract({
    required String businessId,
  }) async {
    try {
      final response = await apiClient.get(
        '/businesses/$businessId/catalogs/entity-contract',
      );

      if (response is Map) {
        return CatalogEntityContract.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
    } catch (_) {
      // Fallback to canonical built-in defaults if network request fails.
    }
    return CatalogEntityContract.defaults();
  }

  // ==========================================
  // Catalog Items
  // ==========================================

  /// Lists items within a catalog with optional search, status, and pagination.
  /// `GET /businesses/{business_id}/catalogs/{catalog_id}/items`
  Future<CatalogItemPage> listCatalogItems({
    required String businessId,
    required String catalogId,
    String? status,
    String? search,
    String? cursor,
    int limit = 25,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await apiClient.get(
      '/businesses/$businessId/catalogs/$catalogId/items',
      queryParameters: queryParams,
    );

    final List<CatalogItem> items = [];
    for (final item in _extractDataList(response)) {
      if (item is Map<String, dynamic>) {
        items.add(CatalogItem.fromJson(item));
      } else if (item is Map) {
        items.add(CatalogItem.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final pagination = response is Map ? response['pagination'] : null;
    final hasMore = pagination is Map && pagination['has_more'] == true;
    final nextCursor = pagination is Map ? pagination['next_cursor']?.toString() : null;
    final requestId = response is Map ? response['request_id']?.toString() : null;

    return CatalogItemPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
      requestId: requestId,
    );
  }

  /// Creates a new catalog item.
  /// `POST /businesses/{business_id}/catalogs/{catalog_id}/items`
  Future<CatalogItem> createCatalogItem({
    required String businessId,
    required String catalogId,
    required CreateCatalogItemRequest request,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('item'),
    };

    final response = await apiClient.post(
      '/businesses/$businessId/catalogs/$catalogId/items',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return CatalogItem.fromJson(_extractDataMap(response));
  }

  /// Retrieves a specific catalog item.
  /// `GET /businesses/{business_id}/catalogs/{catalog_id}/items/{item_id}`
  Future<CatalogItem> getCatalogItem({
    required String businessId,
    required String catalogId,
    required String itemId,
  }) async {
    final response = await apiClient.get(
      '/businesses/$businessId/catalogs/$catalogId/items/$itemId',
    );

    return CatalogItem.fromJson(_extractDataMap(response));
  }

  /// Updates an existing catalog item with optimistic concurrency control.
  /// `PATCH /businesses/{business_id}/catalogs/{catalog_id}/items/{item_id}`
  Future<CatalogItem> updateCatalogItem({
    required String businessId,
    required String catalogId,
    required String itemId,
    required UpdateCatalogItemRequest request,
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': _generateIdempotencyKey('item_update'),
      if (ifMatch != null && ifMatch.isNotEmpty) 'If-Match': ifMatch,
    };

    final response = await apiClient.patch(
      '/businesses/$businessId/catalogs/$catalogId/items/$itemId',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return CatalogItem.fromJson(_extractDataMap(response));
  }

  // ==========================================
  // Variants
  // ==========================================

  /// Lists variants for a specific catalog item.
  /// `GET /businesses/{business_id}/catalog-items/{item_id}/variants`
  Future<VariantPage> listVariants({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await apiClient.get(
      '/businesses/$businessId/catalog-items/$itemId/variants',
      queryParameters: queryParams,
    );

    final List<Variant> items = [];
    for (final item in _extractDataList(response)) {
      if (item is Map<String, dynamic>) {
        items.add(Variant.fromJson(item));
      } else if (item is Map) {
        items.add(Variant.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final pagination = response is Map ? response['pagination'] : null;
    final hasMore = pagination is Map && pagination['has_more'] == true;
    final nextCursor = pagination is Map ? pagination['next_cursor']?.toString() : null;
    final requestId = response is Map ? response['request_id']?.toString() : null;

    return VariantPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
      requestId: requestId,
    );
  }

  /// Creates a new variant for a catalog item.
  /// `POST /businesses/{business_id}/catalog-items/{item_id}/variants`
  Future<Variant> createVariant({
    required String businessId,
    required String itemId,
    required CreateVariantRequest request,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('var'),
    };

    final response = await apiClient.post(
      '/businesses/$businessId/catalog-items/$itemId/variants',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Variant.fromJson(_extractDataMap(response));
  }

  /// Updates an existing variant with optimistic concurrency control.
  /// `PATCH /businesses/{business_id}/variants/{variant_id}`
  Future<Variant> updateVariant({
    required String businessId,
    required String variantId,
    required UpdateVariantRequest request,
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': _generateIdempotencyKey('var_update'),
      if (ifMatch != null && ifMatch.isNotEmpty) 'If-Match': ifMatch,
    };

    final response = await apiClient.patch(
      '/businesses/$businessId/variants/$variantId',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Variant.fromJson(_extractDataMap(response));
  }

  // ==========================================
  // Offers & Pricing
  // ==========================================

  /// Lists offers for a catalog item.
  /// `GET /businesses/{business_id}/catalog-items/{item_id}/offers`
  Future<OfferPage> listOffers({
    required String businessId,
    required String itemId,
    String? status,
    String? cursor,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await apiClient.get(
      '/businesses/$businessId/catalog-items/$itemId/offers',
      queryParameters: queryParams,
    );

    final List<Offer> items = [];
    for (final item in _extractDataList(response)) {
      if (item is Map<String, dynamic>) {
        items.add(Offer.fromJson(item));
      } else if (item is Map) {
        items.add(Offer.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final pagination = response is Map ? response['pagination'] : null;
    final hasMore = pagination is Map && pagination['has_more'] == true;
    final nextCursor = pagination is Map ? pagination['next_cursor']?.toString() : null;
    final requestId = response is Map ? response['request_id']?.toString() : null;

    return OfferPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
      requestId: requestId,
    );
  }

  /// Creates a new offer for a catalog item.
  /// `POST /businesses/{business_id}/catalog-items/{item_id}/offers`
  Future<Offer> createOffer({
    required String businessId,
    required String itemId,
    required CreateOfferRequest request,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('offer'),
    };

    final response = await apiClient.post(
      '/businesses/$businessId/catalog-items/$itemId/offers',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Offer.fromJson(_extractDataMap(response));
  }

  /// Updates an existing offer with optimistic concurrency control.
  /// `PATCH /businesses/{business_id}/offers/{offer_id}`
  Future<Offer> updateOffer({
    required String businessId,
    required String offerId,
    required UpdateOfferRequest request,
    String? ifMatch,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': _generateIdempotencyKey('offer_update'),
      if (ifMatch != null && ifMatch.isNotEmpty) 'If-Match': ifMatch,
    };

    final response = await apiClient.patch(
      '/businesses/$businessId/offers/$offerId',
      body: request.toJson(),
      headers: headers,
      requiresAuth: true,
    );

    return Offer.fromJson(_extractDataMap(response));
  }

  // ==========================================
  // Attribute Schemas
  // ==========================================

  /// Lists attribute schemas defined for a business.
  /// `GET /businesses/{business_id}/attribute-schemas`
  Future<List<AttributeSchema>> listAttributeSchemas({
    required String businessId,
    String? name,
    int? version,
  }) async {
    // List endpoints return cursor pages. Do not silently hide later templates.
    final collected = <AttributeSchema>[];
    final seenIds = <String>{};
    final seenCursors = <String>{};
    String? cursor;
    var pages = 0;
    while (true) {
      if (pages++ >= 200) {
        throw StateError('Schema pagination safety limit reached');
      }
      final queryParams = <String, dynamic>{'limit': '50'};
      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      if (version != null) queryParams['version'] = version.toString();
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await apiClient.get(
        '/businesses/$businessId/attribute-schemas',
        queryParameters: queryParams,
      );
      for (final item in _extractDataList(response)) {
        if (item is! Map) continue;
        final schema = AttributeSchema.fromJson(Map<String, dynamic>.from(item));
        if (seenIds.add(schema.id)) collected.add(schema);
      }
      final pagination = response['pagination'];
      final hasMore = pagination is Map && pagination['has_more'] == true;
      if (!hasMore) return collected;
      final nextCursor = pagination['next_cursor']?.toString();
      if (nextCursor == null || nextCursor.isEmpty ||
          !seenCursors.add(nextCursor)) {
        throw StateError('Invalid catalog schema pagination cursor');
      }
      cursor = nextCursor;
    }
  }

  /// Creates a reusable named schema. The backend generates its attribute keys.
  Future<AttributeSchema> createAttributeSchema({
    required String businessId,
    required CreateAttributeSchemaRequest request,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/businesses/$businessId/attribute-schemas',
      body: request.toJson(),
      headers: {
        'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('schema'),
      },
      requiresAuth: true,
    );
    return AttributeSchema.fromJson(_extractDataMap(response));
  }

  /// Retrieves an attribute schema by ID.
  /// `GET /businesses/{business_id}/attribute-schemas/{schema_id}`
  Future<AttributeSchema> getAttributeSchema({
    required String businessId,
    required String schemaId,
  }) async {
    final response = await apiClient.get(
      '/businesses/$businessId/attribute-schemas/$schemaId',
    );

    return AttributeSchema.fromJson(_extractDataMap(response));
  }
}
