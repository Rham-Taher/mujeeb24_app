import 'package:flutter/foundation.dart';

/// Represents a Catalog in Mujeeb24.
/// Mirrors `Catalog` schema in OpenAPI.
@immutable
class Catalog {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String resourceVersion;

  const Catalog({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
    required this.resourceVersion,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      resourceVersion: json['resource_version']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (description != null) 'description': description,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      'resource_version': resourceVersion,
    };
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isArchived => status == 'archived';
}

/// Request body for creating a new Catalog.
@immutable
class CreateCatalogRequest {
  final String name;
  final String? description;

  const CreateCatalogRequest({
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}

/// Request body for updating an existing Catalog.
@immutable
class UpdateCatalogRequest {
  final String? name;
  final String? description;
  final String? status;

  const UpdateCatalogRequest({
    this.name,
    this.description,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (status != null) map['status'] = status;
    return map;
  }
}

/// Represents a CatalogItem in Mujeeb24.
/// Mirrors `CatalogItem` schema in OpenAPI.
@immutable
class CatalogItem {
  final String id;
  final String businessId;
  final String catalogId;
  final String? attributeSchemaId;
  final int? attributeSchemaVersion;
  final String itemType;
  final String name;
  final String? shortDescription;
  final String? longDescription;
  final String status;
  final String pricingMode;
  final String availabilityMode;
  final String fulfillmentMode;
  final bool requiresConfirmation;
  final Map<String, dynamic> attributes;
  final String resourceVersion;

  const CatalogItem({
    required this.id,
    required this.businessId,
    required this.catalogId,
    this.attributeSchemaId,
    this.attributeSchemaVersion,
    required this.itemType,
    required this.name,
    this.shortDescription,
    this.longDescription,
    required this.status,
    required this.pricingMode,
    required this.availabilityMode,
    required this.fulfillmentMode,
    this.requiresConfirmation = false,
    this.attributes = const {},
    required this.resourceVersion,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      catalogId: json['catalog_id']?.toString() ?? '',
      attributeSchemaId: json['attribute_schema_id']?.toString(),
      attributeSchemaVersion: json['attribute_schema_version'] is int
          ? json['attribute_schema_version'] as int
          : (json['attribute_schema_version'] != null
              ? int.tryParse(json['attribute_schema_version'].toString())
              : null),
      itemType: json['item_type']?.toString() ?? 'physical_good',
      name: json['name']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      longDescription: json['long_description']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      pricingMode: json['pricing_mode']?.toString() ?? 'fixed',
      availabilityMode: json['availability_mode']?.toString() ?? 'stock',
      fulfillmentMode: json['fulfillment_mode']?.toString() ?? 'delivery',
      requiresConfirmation: json['requires_confirmation'] == true,
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
      resourceVersion: json['resource_version']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'catalog_id': catalogId,
      if (attributeSchemaId != null) 'attribute_schema_id': attributeSchemaId,
      if (attributeSchemaVersion != null)
        'attribute_schema_version': attributeSchemaVersion,
      'item_type': itemType,
      'name': name,
      if (shortDescription != null) 'short_description': shortDescription,
      if (longDescription != null) 'long_description': longDescription,
      'status': status,
      'pricing_mode': pricingMode,
      'availability_mode': availabilityMode,
      'fulfillment_mode': fulfillmentMode,
      'requires_confirmation': requiresConfirmation,
      'attributes': attributes,
      'resource_version': resourceVersion,
    };
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isInactive => status == 'inactive';
  bool get isArchived => status == 'archived';
}

/// Request body for creating a new CatalogItem.
@immutable
class CreateCatalogItemRequest {
  final CreateOfferRequest? initialOffer;
  final String? attributeSchemaId;
  final String itemType;
  final String name;
  final String? shortDescription;
  final String? longDescription;
  final String pricingMode;
  final String availabilityMode;
  final String fulfillmentMode;
  final bool requiresConfirmation;
  final Map<String, dynamic> attributes;

  const CreateCatalogItemRequest({
    this.initialOffer,
    this.attributeSchemaId,
    required this.itemType,
    required this.name,
    this.shortDescription,
    this.longDescription,
    required this.pricingMode,
    required this.availabilityMode,
    required this.fulfillmentMode,
    this.requiresConfirmation = false,
    this.attributes = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      if (initialOffer != null) 'initial_offer': initialOffer!.toJson(),
      if (attributeSchemaId != null && attributeSchemaId!.isNotEmpty)
        'attribute_schema_id': attributeSchemaId,
      'item_type': itemType,
      'name': name,
      if (shortDescription != null && shortDescription!.isNotEmpty)
        'short_description': shortDescription,
      if (longDescription != null && longDescription!.isNotEmpty)
        'long_description': longDescription,
      'pricing_mode': pricingMode,
      'availability_mode': availabilityMode,
      'fulfillment_mode': fulfillmentMode,
      'requires_confirmation': requiresConfirmation,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
  }
}

/// Request body for updating a CatalogItem.
@immutable
class UpdateCatalogItemRequest {
  final String? name;
  final String? status;
  final String? itemType;
  final String? shortDescription;
  final String? longDescription;
  final String? pricingMode;
  final String? availabilityMode;
  final String? fulfillmentMode;
  final bool? requiresConfirmation;
  final Map<String, dynamic>? attributes;

  const UpdateCatalogItemRequest({
    this.name,
    this.status,
    this.itemType,
    this.shortDescription,
    this.longDescription,
    this.pricingMode,
    this.availabilityMode,
    this.fulfillmentMode,
    this.requiresConfirmation,
    this.attributes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (status != null) map['status'] = status;
    if (itemType != null) map['item_type'] = itemType;
    if (shortDescription != null) map['short_description'] = shortDescription;
    if (longDescription != null) map['long_description'] = longDescription;
    if (pricingMode != null) map['pricing_mode'] = pricingMode;
    if (availabilityMode != null) map['availability_mode'] = availabilityMode;
    if (fulfillmentMode != null) map['fulfillment_mode'] = fulfillmentMode;
    if (requiresConfirmation != null) {
      map['requires_confirmation'] = requiresConfirmation;
    }
    if (attributes != null) map['attributes'] = attributes;
    return map;
  }
}

/// Represents a Variant of a CatalogItem.
@immutable
class Variant {
  final String id;
  final String businessId;
  final String catalogItemId;
  final String name;
  final Map<String, dynamic> attributes;
  final String status;
  final String resourceVersion;

  const Variant({
    required this.id,
    required this.businessId,
    required this.catalogItemId,
    required this.name,
    this.attributes = const {},
    required this.status,
    required this.resourceVersion,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      catalogItemId: json['catalog_item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
      status: json['status']?.toString() ?? 'active',
      resourceVersion: json['resource_version']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'catalog_item_id': catalogItemId,
      'name': name,
      'attributes': attributes,
      'status': status,
      'resource_version': resourceVersion,
    };
  }

  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get isArchived => status == 'archived';
}

/// Request body for creating a Variant.
@immutable
class CreateVariantRequest {
  final String name;
  final Map<String, dynamic> attributes;

  const CreateVariantRequest({
    required this.name,
    this.attributes = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'attributes': attributes,
    };
  }
}

/// Request body for updating a Variant.
@immutable
class UpdateVariantRequest {
  final String? name;
  final Map<String, dynamic>? attributes;
  final String? status;

  const UpdateVariantRequest({
    this.name,
    this.attributes,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (attributes != null) map['attributes'] = attributes;
    if (status != null) map['status'] = status;
    return map;
  }
}

/// Represents an Offer for a CatalogItem (and optional Variant).
@immutable
class Offer {
  final String id;
  final String businessId;
  final String catalogItemId;
  final String? variantId;
  final String name;
  final String pricingMode;
  final double? amount;
  final String? currency;
  final String? pricingUnit;
  final String? priceSource;
  final String priceVerificationStatus;
  final String? priceCheckedAt;
  final String availabilityMode;
  final String? availabilitySource;
  final String? availabilityCheckedAt;
  final String? availabilityValidUntil;
  final String? availabilityEvidenceRef;
  final String fulfillmentMode;
  final String? validityFrom;
  final String? validityUntil;
  final String availabilityStatus;
  final String status;
  final String resourceVersion;

  const Offer({
    required this.id,
    required this.businessId,
    required this.catalogItemId,
    this.variantId,
    required this.name,
    required this.pricingMode,
    this.amount,
    this.currency,
    this.pricingUnit,
    this.priceSource,
    required this.priceVerificationStatus,
    this.priceCheckedAt,
    required this.availabilityMode,
    this.availabilitySource,
    this.availabilityCheckedAt,
    this.availabilityValidUntil,
    this.availabilityEvidenceRef,
    required this.fulfillmentMode,
    this.validityFrom,
    this.validityUntil,
    required this.availabilityStatus,
    required this.status,
    required this.resourceVersion,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      catalogItemId: json['catalog_item_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      name: json['name']?.toString() ?? '',
      pricingMode: json['pricing_mode']?.toString() ?? 'fixed',
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      currency: json['currency']?.toString(),
      pricingUnit: json['pricing_unit']?.toString(),
      priceSource: json['price_source']?.toString(),
      priceVerificationStatus:
          json['price_verification_status']?.toString() ?? 'unverified',
      priceCheckedAt: json['price_checked_at']?.toString(),
      availabilityMode: json['availability_mode']?.toString() ?? 'stock',
      availabilitySource: json['availability_source']?.toString(),
      availabilityCheckedAt: json['availability_checked_at']?.toString(),
      availabilityValidUntil: json['availability_valid_until']?.toString(),
      availabilityEvidenceRef: json['availability_evidence_ref']?.toString(),
      fulfillmentMode: json['fulfillment_mode']?.toString() ?? 'delivery',
      validityFrom: json['validity_from']?.toString(),
      validityUntil: json['validity_until']?.toString(),
      availabilityStatus:
          json['availability_status']?.toString() ?? 'available',
      status: json['status']?.toString() ?? 'active',
      resourceVersion: json['resource_version']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'catalog_item_id': catalogItemId,
      if (variantId != null) 'variant_id': variantId,
      'name': name,
      'pricing_mode': pricingMode,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (pricingUnit != null) 'pricing_unit': pricingUnit,
      if (priceSource != null) 'price_source': priceSource,
      'price_verification_status': priceVerificationStatus,
      if (priceCheckedAt != null) 'price_checked_at': priceCheckedAt,
      'availability_mode': availabilityMode,
      if (availabilitySource != null)
        'availability_source': availabilitySource,
      if (availabilityCheckedAt != null)
        'availability_checked_at': availabilityCheckedAt,
      if (availabilityValidUntil != null)
        'availability_valid_until': availabilityValidUntil,
      if (availabilityEvidenceRef != null)
        'availability_evidence_ref': availabilityEvidenceRef,
      'fulfillment_mode': fulfillmentMode,
      if (validityFrom != null) 'validity_from': validityFrom,
      if (validityUntil != null) 'validity_until': validityUntil,
      'availability_status': availabilityStatus,
      'status': status,
      'resource_version': resourceVersion,
    };
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isExpired => status == 'expired';
  bool get isAvailable => availabilityStatus == 'available';
  bool get isPriceVerified => priceVerificationStatus == 'verified';
}

/// Request body for creating an Offer.
@immutable
class CreateOfferRequest {
  final String? variantId;
  final String name;
  final String pricingMode;
  final double? amount;
  final String? currency;
  final String? pricingUnit;
  final String availabilityMode;
  final String availabilityStatus;
  final String fulfillmentMode;
  final String? status;

  const CreateOfferRequest({
    this.variantId,
    required this.name,
    required this.pricingMode,
    this.amount,
    this.currency,
    this.pricingUnit,
    required this.availabilityMode,
    required this.availabilityStatus,
    required this.fulfillmentMode,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (variantId != null && variantId!.isNotEmpty) 'variant_id': variantId,
      'name': name,
      'pricing_mode': pricingMode,
      if (amount != null) 'amount': amount,
      if (currency != null && currency!.isNotEmpty) 'currency': currency,
      if (pricingUnit != null && pricingUnit!.isNotEmpty)
        'pricing_unit': pricingUnit,
      'availability_mode': availabilityMode,
      'availability_status': availabilityStatus,
      'fulfillment_mode': fulfillmentMode,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}

/// Request body for updating an Offer, using the full backend OpenAPI contract.
@immutable
class UpdateOfferRequest {
  final String? name;
  final String? pricingMode;
  final double? amount;
  final String? currency;
  final String? pricingUnit;
  final String? availabilityMode;
  final String? availabilityStatus;
  final String? fulfillmentMode;
  final String? variantId;
  final String? status;
  final String? validityFrom;
  final String? validityUntil;
  /// When true, send nullable fields explicitly to clear saved values.
  final bool sendNullableFields;

  const UpdateOfferRequest({
    this.name,
    this.pricingMode,
    this.amount,
    this.currency,
    this.pricingUnit,
    this.availabilityMode,
    this.availabilityStatus,
    this.fulfillmentMode,
    this.variantId,
    this.status,
    this.validityFrom,
    this.validityUntil,
    this.sendNullableFields = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (pricingMode != null) 'pricing_mode': pricingMode,
      if (availabilityMode != null) 'availability_mode': availabilityMode,
      if (availabilityStatus != null) 'availability_status': availabilityStatus,
      if (fulfillmentMode != null) 'fulfillment_mode': fulfillmentMode,
      if (status != null) 'status': status,
      if (sendNullableFields || amount != null) 'amount': amount,
      if (sendNullableFields || currency != null) 'currency': currency,
      if (sendNullableFields || pricingUnit != null) 'pricing_unit': pricingUnit,
      if (sendNullableFields || variantId != null) 'variant_id': variantId,
      if (sendNullableFields || validityFrom != null) 'validity_from': validityFrom,
      if (sendNullableFields || validityUntil != null) 'validity_until': validityUntil,
    };
  }
}

/// Merchant supplies an Arabic label. Only the server generates the opaque key.
@immutable
class AttributeDefinitionInput {
  final String label;
  final String dataType;
  final bool required;
  final int displayOrder;
  final Map<String, dynamic>? validationRules;

  const AttributeDefinitionInput({
    required this.label,
    required this.dataType,
    required this.required,
    required this.displayOrder,
    this.validationRules,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'data_type': dataType,
    'required': required,
    'display_order': displayOrder,
    if (validationRules != null) 'validation_rules': validationRules,
  };
}

@immutable
class CreateAttributeSchemaRequest {
  final String name;
  final List<AttributeDefinitionInput> definitions;
  const CreateAttributeSchemaRequest({
    required this.name,
    required this.definitions,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'definitions': definitions.map((d) => d.toJson()).toList(),
  };
}

/// Attribute definition within an AttributeSchema.
@immutable
class AttributeDefinition {
  final String id;
  final String key;
  final String label;
  final String dataType;
  final bool required;
  final Map<String, dynamic>? validationRules;
  final int displayOrder;

  const AttributeDefinition({
    required this.id,
    required this.key,
    required this.label,
    required this.dataType,
    required this.required,
    this.validationRules,
    this.displayOrder = 0,
  });

  factory AttributeDefinition.fromJson(Map<String, dynamic> json) {
    return AttributeDefinition(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      dataType: json['data_type']?.toString() ?? 'text',
      required: json['required'] == true,
      validationRules: json['validation_rules'] is Map
          ? Map<String, dynamic>.from(json['validation_rules'] as Map)
          : null,
      displayOrder: json['display_order'] is int
          ? json['display_order'] as int
          : (json['display_order'] != null
              ? int.tryParse(json['display_order'].toString()) ?? 0
              : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'label': label,
      'data_type': dataType,
      'required': required,
      if (validationRules != null) 'validation_rules': validationRules,
      'display_order': displayOrder,
    };
  }
}

/// AttributeSchema projection.
@immutable
class AttributeSchema {
  final String id;
  final String businessId;
  final String name;
  final int version;
  final List<AttributeDefinition> definitions;

  const AttributeSchema({
    required this.id,
    required this.businessId,
    required this.name,
    required this.version,
    this.definitions = const [],
  });

  factory AttributeSchema.fromJson(Map<String, dynamic> json) {
    final defsRaw = json['definitions'];
    final List<AttributeDefinition> defs = [];
    if (defsRaw is List) {
      for (final d in defsRaw) {
        if (d is Map<String, dynamic>) {
          defs.add(AttributeDefinition.fromJson(d));
        } else if (d is Map) {
          defs.add(AttributeDefinition.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    return AttributeSchema(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      version: json['version'] is int
          ? json['version'] as int
          : (json['version'] != null
              ? int.tryParse(json['version'].toString()) ?? 1
              : 1),
      definitions: defs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'version': version,
      'definitions': definitions.map((d) => d.toJson()).toList(),
    };
  }
}

/// Dynamic Catalog Entity Contract descriptor returned from
/// `GET /businesses/{business_id}/catalogs/entity-contract`.
/// Contains authoritative Arabic descriptions for all catalog enums.
@immutable
class CatalogEntityContract {
  final Map<String, String> pricingModes;
  final Map<String, String> availabilityModes;
  final Map<String, String> availabilityStatuses;
  final Map<String, String> priceVerificationStatuses;
  final Map<String, String> fulfillmentModes;
  final Map<String, String> itemStatuses;
  final Map<String, String> catalogStatuses;
  final Map<String, String> variantStatuses;
  final Map<String, String> offerStatuses;

  const CatalogEntityContract({
    required this.pricingModes,
    required this.availabilityModes,
    required this.availabilityStatuses,
    required this.priceVerificationStatuses,
    required this.fulfillmentModes,
    required this.itemStatuses,
    required this.catalogStatuses,
    required this.variantStatuses,
    required this.offerStatuses,
  });

  factory CatalogEntityContract.fromJson(Map<String, dynamic> json) {
    final source = json['enums'] is Map
        ? Map<String, dynamic>.from(json['enums'] as Map)
        : json;

    Map<String, String> parseMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      if (val is List) {
        final result = <String, String>{};
        for (final item in val) {
          if (item is Map) {
            final code = item['code'] ?? item['value'] ?? item['id'];
            final label =
                item['label'] ?? item['name'] ?? item['title'] ?? code;
            if (code != null) {
              result[code.toString()] = label.toString();
            }
          }
        }
        return result;
      }
      return {};
    }

    return CatalogEntityContract(
      pricingModes: parseMap(source['pricing_modes'] ?? source['pricing_mode']),
      availabilityModes:
          parseMap(source['availability_modes'] ?? source['availability_mode']),
      availabilityStatuses: parseMap(
          source['availability_statuses'] ?? source['availability_status']),
      priceVerificationStatuses: parseMap(
          source['price_verification_statuses'] ??
              source['price_verification_status']),
      fulfillmentModes:
          parseMap(source['fulfillment_modes'] ?? source['fulfillment_mode']),
      itemStatuses: parseMap(source['item_statuses'] ?? source['item_status']),
      catalogStatuses: parseMap(source['catalog_statuses'] ??
          source['catalog_status'] ??
          source['status']),
      variantStatuses:
          parseMap(source['variant_statuses'] ?? source['variant_status']),
      offerStatuses: parseMap(source['offer_statuses'] ?? source['offer_status']),
    );
  }

  /// Default fallback based on canonical SQL migration CHECK constraints
  /// in case the API call has not loaded yet or fails.
  factory CatalogEntityContract.defaults() {
    return const CatalogEntityContract(
      pricingModes: {
        'fixed': 'السعر ثابت ومحدد في العرض',
        'starting_from': 'السعر يبدأ من هذه القيمة وقد يزيد حسب الخيارات',
        'per_unit': 'السعر لكل وحدة (amount + pricing_unit مطلوبان)',
        'per_person': 'السعر لكل شخص (amount + pricing_unit مطلوبان)',
        'per_day': 'السعر لكل يوم (amount + pricing_unit مطلوبان)',
        'quote_required': 'السعر يُحدد عند الطلب (amount غير مطلوب)',
        'dynamic': 'السعر متغير (يحتاج مصدر تحقق)',
      },
      availabilityModes: {
        'stock': 'التوفر يعتمد على المخزون الفعلي',
        'schedule': 'التوفر يعتمد على جدول زمني ومواعيد',
        'supplier_check': 'التوفر يتطلب فحص المزود الفعلي',
        'always_available': 'متاح دائمًا ضمن نطاق العرض',
        'unknown': 'التوفر غير معروف حاليًا',
      },
      availabilityStatuses: {
        'available': 'متاح حاليًا',
        'unavailable': 'غير متاح حاليًا',
        'unknown': 'الحالة غير معروفة',
        'requires_check': 'يتطلب فحصًا إضافيًا',
        'stale': 'البيانات قديمة وتتطلب تحديثًا',
      },
      priceVerificationStatuses: {
        'unverified': 'السعر لم يُتحقق منه بعد',
        'verified': 'تم التحقق من صحة السعر',
        'stale': 'السعر قديم وقد لا يعكس القيمة الحالية',
        'rejected': 'تم رفض السعر أثناء المراجعة',
      },
      fulfillmentModes: {
        'delivery': 'تسليم مادي / توصيل وشحن',
        'pickup': 'استلام من الفرع أو المتجر',
        'digital': 'تسليم رقمي / إلكتروني فوري',
        'appointment': 'موعد محدد مسبقًا',
        'travel': 'حجز سفر / رحلة محددة',
        'manual': 'تنفيذ يدوي / مخصص',
      },
      catalogStatuses: {
        'draft': 'مسودة',
        'active': 'نشط',
        'archived': 'مؤرشف',
      },
      itemStatuses: {
        'draft': 'مسودة',
        'active': 'نشط',
        'inactive': 'غير نشط',
        'archived': 'مؤرشف',
      },
      variantStatuses: {
        'active': 'نشط',
        'inactive': 'غير نشط',
        'archived': 'مؤرشف',
      },
      offerStatuses: {
        'draft': 'مسودة',
        'active': 'نشط',
        'inactive': 'غير نشط',
        'expired': 'منتهي',
        'archived': 'مؤرشف',
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pricing_modes': pricingModes,
      'availability_modes': availabilityModes,
      'availability_statuses': availabilityStatuses,
      'price_verification_statuses': priceVerificationStatuses,
      'fulfillment_modes': fulfillmentModes,
      'catalog_statuses': catalogStatuses,
      'item_statuses': itemStatuses,
      'variant_statuses': variantStatuses,
      'offer_statuses': offerStatuses,
    };
  }

  String labelPricingMode(String mode) =>
      pricingModes[mode] ?? mode;
  String labelAvailabilityMode(String mode) =>
      availabilityModes[mode] ?? mode;
  String labelAvailabilityStatus(String status) =>
      availabilityStatuses[status] ?? status;
  String labelPriceVerification(String status) =>
      priceVerificationStatuses[status] ?? status;
  String labelFulfillmentMode(String mode) =>
      fulfillmentModes[mode] ?? mode;
  String labelItemStatus(String status) =>
      itemStatuses[status] ?? status;
  String labelCatalogStatus(String status) =>
      catalogStatuses[status] ?? status;
  String labelVariantStatus(String status) =>
      variantStatuses[status] ?? status;
  String labelOfferStatus(String status) =>
      offerStatuses[status] ?? status;

  String labelFor(String category, String code) {
    switch (category) {
      case 'pricing_mode':
        return labelPricingMode(code);
      case 'availability_mode':
        return labelAvailabilityMode(code);
      case 'availability_status':
        return labelAvailabilityStatus(code);
      case 'price_verification_status':
        return labelPriceVerification(code);
      case 'fulfillment_mode':
        return labelFulfillmentMode(code);
      case 'item_status':
        return labelItemStatus(code);
      case 'catalog_status':
      case 'status':
        return labelCatalogStatus(code);
      case 'variant_status':
        return labelVariantStatus(code);
      case 'offer_status':
        return labelOfferStatus(code);
      default:
        return code;
    }
  }
}

/// Generic page structure for paginated lists.
@immutable
class CatalogPage {
  final List<Catalog> items;
  final bool hasMore;
  final String? nextCursor;
  final String? requestId;

  const CatalogPage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
    this.requestId,
  });

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final list = <Catalog>[];
    final rawItems = json['items'] ?? json['data'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          list.add(Catalog.fromJson(item));
        } else if (item is Map) {
          list.add(Catalog.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final pagination = json['pagination'];
    return CatalogPage(
      items: list,
      hasMore: json['has_more'] == true ||
          (pagination is Map && pagination['has_more'] == true),
      nextCursor: json['next_cursor']?.toString() ??
          (pagination is Map ? pagination['next_cursor']?.toString() : null),
      requestId: json['request_id']?.toString(),
    );
  }
}

@immutable
class CatalogItemPage {
  final List<CatalogItem> items;
  final bool hasMore;
  final String? nextCursor;
  final String? requestId;

  const CatalogItemPage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
    this.requestId,
  });

  factory CatalogItemPage.fromJson(Map<String, dynamic> json) {
    final list = <CatalogItem>[];
    final rawItems = json['items'] ?? json['data'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          list.add(CatalogItem.fromJson(item));
        } else if (item is Map) {
          list.add(CatalogItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final pagination = json['pagination'];
    return CatalogItemPage(
      items: list,
      hasMore: json['has_more'] == true ||
          (pagination is Map && pagination['has_more'] == true),
      nextCursor: json['next_cursor']?.toString() ??
          (pagination is Map ? pagination['next_cursor']?.toString() : null),
      requestId: json['request_id']?.toString(),
    );
  }
}

@immutable
class VariantPage {
  final List<Variant> items;
  final bool hasMore;
  final String? nextCursor;
  final String? requestId;

  const VariantPage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
    this.requestId,
  });

  factory VariantPage.fromJson(Map<String, dynamic> json) {
    final list = <Variant>[];
    final rawItems = json['items'] ?? json['data'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          list.add(Variant.fromJson(item));
        } else if (item is Map) {
          list.add(Variant.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final pagination = json['pagination'];
    return VariantPage(
      items: list,
      hasMore: json['has_more'] == true ||
          (pagination is Map && pagination['has_more'] == true),
      nextCursor: json['next_cursor']?.toString() ??
          (pagination is Map ? pagination['next_cursor']?.toString() : null),
      requestId: json['request_id']?.toString(),
    );
  }
}

@immutable
class OfferPage {
  final List<Offer> items;
  final bool hasMore;
  final String? nextCursor;
  final String? requestId;

  const OfferPage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
    this.requestId,
  });

  factory OfferPage.fromJson(Map<String, dynamic> json) {
    final list = <Offer>[];
    final rawItems = json['items'] ?? json['data'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          list.add(Offer.fromJson(item));
        } else if (item is Map) {
          list.add(Offer.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final pagination = json['pagination'];
    return OfferPage(
      items: list,
      hasMore: json['has_more'] == true ||
          (pagination is Map && pagination['has_more'] == true),
      nextCursor: json['next_cursor']?.toString() ??
          (pagination is Map ? pagination['next_cursor']?.toString() : null),
      requestId: json['request_id']?.toString(),
    );
  }
}
