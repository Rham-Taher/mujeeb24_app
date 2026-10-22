import 'package:flutter/foundation.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/models/catalog_models.dart';

/// State management provider for Catalog, Items, Variants, Offers, and Entity Contract.
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;

  CatalogProvider({required this.catalogRepository});

  // ==========================================
  // Catalogs State
  // ==========================================
  List<Catalog> _catalogs = [];
  Catalog? _selectedCatalog;
  bool _isLoadingCatalogs = false;
  String? _catalogsError;
  String _catalogStatusFilter = 'all';
  bool _catalogsHasMore = false;
  String? _catalogsNextCursor;

  List<Catalog> get catalogs => _catalogs;
  Catalog? get selectedCatalog => _selectedCatalog;
  bool get isLoadingCatalogs => _isLoadingCatalogs;
  String? get catalogsError => _catalogsError;
  String get catalogStatusFilter => _catalogStatusFilter;
  bool get catalogsHasMore => _catalogsHasMore;

  // ==========================================
  // Catalog Items State
  // ==========================================
  List<CatalogItem> _catalogItems = [];
  CatalogItem? _selectedItem;
  bool _isLoadingItems = false;
  String? _itemsError;
  String _itemStatusFilter = 'all';
  String _itemSearchQuery = '';
  bool _itemsHasMore = false;
  String? _itemsNextCursor;

  List<CatalogItem> get catalogItems => _catalogItems;
  CatalogItem? get selectedItem => _selectedItem;
  bool get isLoadingItems => _isLoadingItems;
  String? get itemsError => _itemsError;
  String get itemStatusFilter => _itemStatusFilter;
  String get itemSearchQuery => _itemSearchQuery;
  bool get itemsHasMore => _itemsHasMore;

  // ==========================================
  // Item Sub-resources: Variants & Offers
  // ==========================================
  List<Variant> _variants = [];
  List<Offer> _offers = [];
  bool _variantsHasMore = false;
  bool _offersHasMore = false;
  String? _variantsCursor;
  String? _offersCursor;
  bool _loadingMoreVariants = false;
  bool _loadingMoreOffers = false;
  bool _isLoadingItemDetail = false;
  String? _itemDetailError;
  String? _variantsError;
  String? _offersError;
  bool _isLoadingVariants = false;
  bool _isLoadingOffers = false;

  List<Variant> get variants => _variants;
  List<Offer> get offers => _offers;
  bool get variantsHasMore => _variantsHasMore;
  bool get offersHasMore => _offersHasMore;
  bool get loadingMoreVariants => _loadingMoreVariants;
  bool get loadingMoreOffers => _loadingMoreOffers;
  bool get isLoadingItemDetail => _isLoadingItemDetail;
  String? get itemDetailError => _itemDetailError;
  String? get variantsError => _variantsError;
  String? get offersError => _offersError;
  bool get isLoadingVariants => _isLoadingVariants;
  bool get isLoadingOffers => _isLoadingOffers;

  // ==========================================
  // Attribute Schemas & Entity Contract
  // ==========================================
  List<AttributeSchema> _attributeSchemas = [];
  CatalogEntityContract _entityContract = CatalogEntityContract.defaults();
  bool _isLoadingContract = false;
  bool _hasLoadedContract = false;
  String? _contractError;
  String? _schemasError;

  List<AttributeSchema> get attributeSchemas => _attributeSchemas;
  CatalogEntityContract get entityContract => _entityContract;
  bool get isLoadingContract => _isLoadingContract;
  bool get hasLoadedContract => _hasLoadedContract;
  String? get contractError => _contractError;
  String? get schemasError => _schemasError;

  // ==========================================
  // Action State (Mutations)
  // ==========================================
  bool _isPerformingAction = false;
  String? _actionError;

  bool get isPerformingAction => _isPerformingAction;
  String? get actionError => _actionError;

  // ==========================================
  // Catalog Methods
  // ==========================================

  void setCatalogStatusFilter(String status) {
    if (_catalogStatusFilter != status) {
      _catalogStatusFilter = status;
      notifyListeners();
    }
  }

  void selectCatalog(Catalog? catalog) {
    _selectedCatalog = catalog;
    _catalogItems = [];
    _itemsHasMore = false;
    _itemsNextCursor = null;
    _selectedItem = null;
    _variants = [];
    _offers = [];
    _variantsCursor = null;
    _offersCursor = null;
    _variantsHasMore = false;
    _offersHasMore = false;
    _variantsError = null;
    _offersError = null;
    notifyListeners();
  }

  Future<void> fetchCatalogs(
    String businessId, {
    bool refresh = false,
    String? status,
  }) async {
    if (businessId.isEmpty) return;
    _isLoadingCatalogs = true;
    _catalogsError = null;
    notifyListeners();

    try {
      final effectiveStatus = status ?? _catalogStatusFilter;
      final page = await catalogRepository.listCatalogs(
        businessId: businessId,
        status: effectiveStatus != 'all' ? effectiveStatus : null,
      );
      _catalogs = page.items;
      _catalogsHasMore = page.hasMore;
      _catalogsNextCursor = page.nextCursor;
      if (_selectedCatalog != null) {
        _selectedCatalog = _catalogs.firstWhere(
          (c) => c.id == _selectedCatalog!.id,
          orElse: () => _selectedCatalog!,
        );
      }
    } on ApiErrorEnvelope catch (e) {
      _catalogsError = e.error.message;
    } catch (e) {
      _catalogsError = e.toString();
    } finally {
      _isLoadingCatalogs = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCatalogs(String businessId) async {
    if (_isLoadingCatalogs || !_catalogsHasMore || _catalogsNextCursor == null) return;
    _isLoadingCatalogs = true;
    _catalogsError = null;
    notifyListeners();
    try {
      final page = await catalogRepository.listCatalogs(
        businessId: businessId,
        status: _catalogStatusFilter == 'all' ? null : _catalogStatusFilter,
        cursor: _catalogsNextCursor,
      );
      final known = _catalogs.map((e) => e.id).toSet();
      _catalogs.addAll(page.items.where((e) => known.add(e.id)));
      _catalogsHasMore = page.hasMore;
      _catalogsNextCursor = page.nextCursor;
    } catch (e) {
      _catalogsError = e.toString();
    } finally {
      _isLoadingCatalogs = false;
      notifyListeners();
    }
  }

  Future<Catalog?> createCatalog(
    String businessId,
    CreateCatalogRequest request,
  ) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final created = await catalogRepository.createCatalog(
        businessId: businessId,
        request: request,
      );
      _catalogs = [created, ..._catalogs];
      return created;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<Catalog?> updateCatalog(
    String businessId,
    String catalogId,
    UpdateCatalogRequest request, {
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await catalogRepository.updateCatalog(
        businessId: businessId,
        catalogId: catalogId,
        request: request,
        ifMatch: ifMatch ?? _selectedCatalog?.resourceVersion,
      );

      final index = _catalogs.indexWhere((c) => c.id == catalogId);
      if (index >= 0) {
        _catalogs[index] = updated;
      }
      if (_selectedCatalog?.id == catalogId) {
        _selectedCatalog = updated;
      }
      return updated;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Catalog Item Methods
  // ==========================================

  void setItemStatusFilter(String status) {
    if (_itemStatusFilter != status) {
      _itemStatusFilter = status;
      notifyListeners();
    }
  }

  void setItemSearchQuery(String query) {
    _itemSearchQuery = query;
    notifyListeners();
  }

  void selectItem(CatalogItem? item) {
    _selectedItem = item;
    _variants = [];
    _offers = [];
    notifyListeners();
  }

  Future<void> fetchCatalogItems(
    String businessId,
    String catalogId, {
    bool refresh = false,
    String? status,
    String? search,
  }) async {
    if (businessId.isEmpty || catalogId.isEmpty) return;
    _isLoadingItems = true;
    _itemsError = null;
    notifyListeners();

    try {
      final effectiveStatus = status ?? _itemStatusFilter;
      final effectiveSearch = search ?? _itemSearchQuery;

      final page = await catalogRepository.listCatalogItems(
        businessId: businessId,
        catalogId: catalogId,
        status: effectiveStatus != 'all' ? effectiveStatus : null,
        search: effectiveSearch.isNotEmpty ? effectiveSearch : null,
      );
      _catalogItems = page.items;
      _itemsHasMore = page.hasMore;
      _itemsNextCursor = page.nextCursor;
      if (_selectedItem != null) {
        _selectedItem = _catalogItems.firstWhere(
          (i) => i.id == _selectedItem!.id,
          orElse: () => _selectedItem!,
        );
      }
    } on ApiErrorEnvelope catch (e) {
      _itemsError = e.error.message;
    } catch (e) {
      _itemsError = e.toString();
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCatalogItems(String businessId, String catalogId) async {
    if (_isLoadingItems || !_itemsHasMore || _itemsNextCursor == null) return;
    _isLoadingItems = true;
    _itemsError = null;
    notifyListeners();
    try {
      final page = await catalogRepository.listCatalogItems(
        businessId: businessId,
        catalogId: catalogId,
        status: _itemStatusFilter == 'all' ? null : _itemStatusFilter,
        search: _itemSearchQuery.isEmpty ? null : _itemSearchQuery,
        cursor: _itemsNextCursor,
      );
      final known = _catalogItems.map((e) => e.id).toSet();
      _catalogItems.addAll(page.items.where((e) => known.add(e.id)));
      _itemsHasMore = page.hasMore;
      _itemsNextCursor = page.nextCursor;
    } catch (e) {
      _itemsError = e.toString();
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  Future<CatalogItem?> createCatalogItem(
    String businessId,
    String catalogId,
    CreateCatalogItemRequest request,
  ) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final created = await catalogRepository.createCatalogItem(
        businessId: businessId,
        catalogId: catalogId,
        request: request,
      );
      _catalogItems = [created, ..._catalogItems];
      return created;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<CatalogItem?> updateCatalogItem(
    String businessId,
    String catalogId,
    String itemId,
    UpdateCatalogItemRequest request, {
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await catalogRepository.updateCatalogItem(
        businessId: businessId,
        catalogId: catalogId,
        itemId: itemId,
        request: request,
        ifMatch: ifMatch ?? _selectedItem?.resourceVersion,
      );

      final index = _catalogItems.indexWhere((i) => i.id == itemId);
      if (index >= 0) {
        _catalogItems[index] = updated;
      }
      if (_selectedItem?.id == itemId) {
        _selectedItem = updated;
      }
      return updated;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Item Detail & Sub-resources
  // ==========================================

  /// Load the product first. A broken variants or offers endpoint must
  /// never turn a successfully saved product into an unusable detail screen.
  Future<void> fetchItemDetail(
    String businessId,
    String catalogId,
    String itemId,
  ) async {
    if (businessId.isEmpty || catalogId.isEmpty || itemId.isEmpty) return;
    _isLoadingItemDetail = true;
    _itemDetailError = null;
    _variantsError = null;
    _offersError = null;
    if (_selectedItem?.id != itemId) _selectedItem = null;
    _variants = [];
    _offers = [];
    _variantsCursor = null;
    _offersCursor = null;
    _variantsHasMore = false;
    _offersHasMore = false;
    notifyListeners();

    try {
      final item = await catalogRepository.getCatalogItem(
        businessId: businessId, catalogId: catalogId, itemId: itemId);
      _selectedItem = item;
    } on ApiErrorEnvelope catch (e) {
      _itemDetailError = e.error.message;
    } catch (_) {
      _itemDetailError = 'تعذر تحميل بيانات المنتج. أعد المحاولة.';
    } finally {
      _isLoadingItemDetail = false;
      notifyListeners();
    }
    if (_selectedItem?.id != itemId || _itemDetailError != null) return;
    await Future.wait([
      refreshVariants(businessId, itemId),
      refreshOffers(businessId, itemId),
    ]);
  }

  /// Separately retry product variations without reloading or losing the item.
  Future<void> refreshVariants(String businessId, String itemId) async {
    _variantsError = null;
    _isLoadingVariants = true;
    notifyListeners();
    try {
      final page = await catalogRepository.listVariants(
        businessId: businessId, itemId: itemId);
      if (_selectedItem?.id != itemId) return;
      _variants = page.items;
      _variantsCursor = page.nextCursor;
      _variantsHasMore = page.hasMore;
    } catch (_) {
      if (_selectedItem?.id != itemId) return;
      _variantsError = 'تعذر تحميل متغيرات المنتج. يمكنك إعادة المحاولة.';
    } finally {
      _isLoadingVariants = false;
      notifyListeners();
    }
  }

  /// An offers failure must not hide the product or its variations.
  Future<void> refreshOffers(String businessId, String itemId) async {
    _offersError = null;
    _isLoadingOffers = true;
    notifyListeners();
    try {
      final page = await catalogRepository.listOffers(
        businessId: businessId, itemId: itemId);
      if (_selectedItem?.id != itemId) return;
      _offers = page.items;
      _offersCursor = page.nextCursor;
      _offersHasMore = page.hasMore;
    } catch (_) {
      if (_selectedItem?.id != itemId) return;
      _offersError = 'تعذر تحميل عروض وأسعار المنتج. أعد المحاولة.';
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVariants(String businessId, String itemId) async {
    if (_loadingMoreVariants || !_variantsHasMore || _variantsCursor == null) return;
    _loadingMoreVariants = true;
    notifyListeners();
    try {
      final page = await catalogRepository.listVariants(
        businessId: businessId, itemId: itemId, cursor: _variantsCursor);
      final known = _variants.map((v) => v.id).toSet();
      _variants.addAll(page.items.where((v) => known.add(v.id)));
      _variantsHasMore = page.hasMore;
      _variantsCursor = page.nextCursor;
    } catch (e) {
      _variantsError = 'تعذر تحميل بقية المتغيرات. أعد المحاولة.';
    } finally {
      _loadingMoreVariants = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOffers(String businessId, String itemId) async {
    if (_loadingMoreOffers || !_offersHasMore || _offersCursor == null) return;
    _loadingMoreOffers = true;
    notifyListeners();
    try {
      final page = await catalogRepository.listOffers(
        businessId: businessId, itemId: itemId, cursor: _offersCursor);
      final known = _offers.map((o) => o.id).toSet();
      _offers.addAll(page.items.where((o) => known.add(o.id)));
      _offersHasMore = page.hasMore;
      _offersCursor = page.nextCursor;
    } catch (e) {
      _offersError = 'تعذر تحميل بقية الأسعار. أعد المحاولة.';
    } finally {
      _loadingMoreOffers = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Variants
  // ==========================================

  Future<Variant?> createVariant(
    String businessId,
    String itemId,
    CreateVariantRequest request,
  ) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final created = await catalogRepository.createVariant(
        businessId: businessId,
        itemId: itemId,
        request: request,
      );
      _variants = [..._variants, created];
      return created;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<Variant?> updateVariant(
    String businessId,
    String variantId,
    UpdateVariantRequest request, {
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final currentVariant = _variants.firstWhere(
        (v) => v.id == variantId,
        orElse: () => Variant(
          id: variantId,
          businessId: businessId,
          catalogItemId: '',
          name: '',
          status: 'active',
          resourceVersion: '1',
        ),
      );

      final updated = await catalogRepository.updateVariant(
        businessId: businessId,
        variantId: variantId,
        request: request,
        ifMatch: ifMatch ?? currentVariant.resourceVersion,
      );

      final index = _variants.indexWhere((v) => v.id == variantId);
      if (index >= 0) {
        _variants[index] = updated;
      }
      return updated;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Offers
  // ==========================================

  Future<Offer?> createOffer(
    String businessId,
    String itemId,
    CreateOfferRequest request,
  ) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final created = await catalogRepository.createOffer(
        businessId: businessId,
        itemId: itemId,
        request: request,
      );
      _offers = [..._offers, created];
      return created;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<Offer?> updateOffer(
    String businessId,
    String offerId,
    UpdateOfferRequest request, {
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final currentOffer = _offers.firstWhere(
        (o) => o.id == offerId,
        orElse: () => Offer(
          id: offerId,
          businessId: businessId,
          catalogItemId: '',
          name: '',
          pricingMode: 'fixed',
          priceVerificationStatus: 'unverified',
          availabilityMode: 'stock',
          fulfillmentMode: 'delivery',
          availabilityStatus: 'available',
          status: 'active',
          resourceVersion: '1',
        ),
      );

      final updated = await catalogRepository.updateOffer(
        businessId: businessId,
        offerId: offerId,
        request: request,
        ifMatch: ifMatch ?? currentOffer.resourceVersion,
      );

      final index = _offers.indexWhere((o) => o.id == offerId);
      if (index >= 0) {
        _offers[index] = updated;
      }
      return updated;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Contract & Schemas
  // ==========================================

  Future<void> fetchEntityContract(String businessId) async {
    if (businessId.isEmpty) return;
    _isLoadingContract = true;
    _hasLoadedContract = false;
    _contractError = null;
    notifyListeners();

    try {
      final contract = await catalogRepository.getCatalogEntityContract(
        businessId: businessId,
      );
      if (contract.pricingModes.isEmpty ||
          contract.availabilityStatuses.isEmpty ||
          contract.fulfillmentModes.isEmpty) {
        throw StateError('incomplete catalog entity contract');
      }
      _entityContract = contract;
      _hasLoadedContract = true;
    } catch (_) {
      // Defaults may explain existing records; never use them to authorize saves.
      _hasLoadedContract = false;
      _contractError = 'تعذر تحميل اختيارات الكتالوج. أعد المحاولة.';
    } finally {
      _isLoadingContract = false;
      notifyListeners();
    }
  }

  Future<AttributeSchema?> createAttributeSchema(
    String businessId, CreateAttributeSchemaRequest request) async {
    if (_isPerformingAction) return null;
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();
    try {
      final created = await catalogRepository.createAttributeSchema(
        businessId: businessId, request: request);
      _attributeSchemas = [created, ..._attributeSchemas];
      return created;
    } on ApiErrorEnvelope catch (error) {
      _actionError = error.error.message;
      return null;
    } catch (_) {
      _actionError = 'تعذر حفظ قالب المواصفات. تحقق من الاتصال.';
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttributeSchemas(String businessId) async {
    if (businessId.isEmpty) return;
    _schemasError = null;
    try {
      final schemas = await catalogRepository.listAttributeSchemas(
        businessId: businessId,
      );
      _attributeSchemas = schemas;
      notifyListeners();
    } catch (_) {
      _schemasError = 'تعذر تحميل قوالب المواصفات. أعد المحاولة.';
      notifyListeners();
    }
  }
}
