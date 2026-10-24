import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';

/// Models for Subscriptions, Quotas, Plans, and Manual Payments.
/// Conforms to Mujeeb_24_Pricing_Contract_v2.0.md and Go backend DTOs.

/// Represents the merchant's current subscription snapshot and quota projection.
/// Maps directly to Go backend `dto.MerchantSubscriptionView` and `queries.MerchantSubscriptionView`.
class MerchantSubscriptionView {
  final bool hasSubscription;
  final String? id;
  final String businessId;
  final String? planId;
  final String? planCode;
  final String? planName;
  final int? planVersion;
  final String? status; // 'PENDING', 'ACTIVE', 'EXPIRED', 'CANCELLED'
  final String? periodStart;
  final String? periodEnd;
  final int? priceYerSnapshot;
  final int? amountDueYer;
  final int? aiReplyLimit;
  final int? aiRepliesUsed;
  final int? aiRepliesRemaining;
  final int? aiCatalogLimit;
  final int? channelLimit;
  final int? channelCeiling;
  final int? seatLimit;
  final int activeChannels;
  final int activeSeats;
  final int? daysRemaining;
  final String? activatedAt;
  final String? createdAt;

  const MerchantSubscriptionView({
    required this.hasSubscription,
    this.id,
    required this.businessId,
    this.planId,
    this.planCode,
    this.planName,
    this.planVersion,
    this.status,
    this.periodStart,
    this.periodEnd,
    this.priceYerSnapshot,
    this.amountDueYer,
    this.aiReplyLimit,
    this.aiRepliesUsed,
    this.aiRepliesRemaining,
    this.aiCatalogLimit,
    this.channelLimit,
    this.channelCeiling,
    this.seatLimit,
    this.activeChannels = 0,
    this.activeSeats = 0,
    this.daysRemaining,
    this.activatedAt,
    this.createdAt,
  });

  bool get isActive => status?.toUpperCase() == 'ACTIVE';
  bool get isPending => status?.toUpperCase() == 'PENDING';
  bool get isExpired => status?.toUpperCase() == 'EXPIRED';
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';

  /// Calculates AI reply consumption ratio (0.0 to 1.0+)
  double get aiRepliesProgress {
    if (aiReplyLimit == null || aiReplyLimit! <= 0) return 0.0;
    final used = (aiRepliesUsed ?? 0).toDouble();
    return (used / aiReplyLimit!.toDouble()).clamp(0.0, 1.0);
  }

  /// Calculates channel consumption ratio
  double get channelProgress {
    if (channelLimit == null || channelLimit! <= 0) return 0.0;
    return (activeChannels / channelLimit!).clamp(0.0, 1.0);
  }

  /// Calculates team seats consumption ratio
  double get seatProgress {
    if (seatLimit == null || seatLimit! <= 0) return 0.0;
    return (activeSeats / seatLimit!).clamp(0.0, 1.0);
  }

  /// Quota color rule:
  /// - Green (< 70%)
  /// - Orange (70% to < 90%)
  /// - Red (>= 90%)
  static Color getQuotaColor(double ratio) {
    if (ratio < 0.70) return AppColors.statusSuccess;
    if (ratio < 0.90) return AppColors.statusWarning;
    return AppColors.statusError;
  }

  String get localizedStatus {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'نشط';
      case 'PENDING':
        return 'قيد المراجعة';
      case 'EXPIRED':
        return 'منتهي';
      case 'CANCELLED':
        return 'ملغى';
      default:
        return status ?? 'غير محدد';
    }
  }

  Color get statusBadgeColor {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.statusSuccess;
      case 'PENDING':
        return AppColors.statusWarning;
      case 'EXPIRED':
        return AppColors.statusError;
      case 'CANCELLED':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  factory MerchantSubscriptionView.fromJson(Map<String, dynamic> json) {
    return MerchantSubscriptionView(
      hasSubscription: json['has_subscription'] as bool? ?? false,
      id: json['id'] as String?,
      businessId: json['business_id'] as String? ?? '',
      planId: json['plan_id'] as String?,
      planCode: json['plan_code'] as String?,
      planName: json['plan_name'] as String?,
      planVersion: (json['plan_version'] as num?)?.toInt(),
      status: json['status'] as String?,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      priceYerSnapshot: (json['price_yer_snapshot'] as num?)?.toInt(),
      amountDueYer: (json['amount_due_yer'] as num?)?.toInt(),
      aiReplyLimit: (json['ai_reply_limit'] as num?)?.toInt(),
      aiRepliesUsed: (json['ai_replies_used'] as num?)?.toInt(),
      aiRepliesRemaining: (json['ai_replies_remaining'] as num?)?.toInt(),
      aiCatalogLimit: (json['ai_catalog_limit'] as num?)?.toInt(),
      channelLimit: (json['channel_limit'] as num?)?.toInt(),
      channelCeiling: (json['channel_ceiling'] as num?)?.toInt(),
      seatLimit: (json['seat_limit'] as num?)?.toInt(),
      activeChannels: (json['active_channels'] as num?)?.toInt() ?? 0,
      activeSeats: (json['active_seats'] as num?)?.toInt() ?? 0,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      activatedAt: json['activated_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'has_subscription': hasSubscription,
    if (id != null) 'id': id,
    'business_id': businessId,
    if (planId != null) 'plan_id': planId,
    if (planCode != null) 'plan_code': planCode,
    if (planName != null) 'plan_name': planName,
    if (planVersion != null) 'plan_version': planVersion,
    if (status != null) 'status': status,
    if (periodStart != null) 'period_start': periodStart,
    if (periodEnd != null) 'period_end': periodEnd,
    if (priceYerSnapshot != null) 'price_yer_snapshot': priceYerSnapshot,
    if (amountDueYer != null) 'amount_due_yer': amountDueYer,
    if (aiReplyLimit != null) 'ai_reply_limit': aiReplyLimit,
    if (aiRepliesUsed != null) 'ai_replies_used': aiRepliesUsed,
    if (aiRepliesRemaining != null) 'ai_replies_remaining': aiRepliesRemaining,
    if (aiCatalogLimit != null) 'ai_catalog_limit': aiCatalogLimit,
    if (channelLimit != null) 'channel_limit': channelLimit,
    if (channelCeiling != null) 'channel_ceiling': channelCeiling,
    if (seatLimit != null) 'seat_limit': seatLimit,
    'active_channels': activeChannels,
    'active_seats': activeSeats,
    if (daysRemaining != null) 'days_remaining': daysRemaining,
    if (activatedAt != null) 'activated_at': activatedAt,
    if (createdAt != null) 'created_at': createdAt,
  };
}

/// Commercial subscription tier strictly adhering to Mujeeb_24_Pricing_Contract_v2.0.md.
class PricingPlan {
  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final int priceYer;
  final String billingInterval; // MONTH
  final int aiReplyLimit;
  final int aiCatalogLimit;
  final int includedChannels;
  final int channelCeiling;
  final int seatLimit;
  final int internalAiCostBudgetYer;
  final String descriptionAr;
  final String descriptionEn;
  final bool isPopular;
  final bool isCustom;

  const PricingPlan({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.priceYer,
    this.billingInterval = 'MONTH',
    required this.aiReplyLimit,
    required this.aiCatalogLimit,
    required this.includedChannels,
    required this.channelCeiling,
    required this.seatLimit,
    required this.internalAiCostBudgetYer,
    required this.descriptionAr,
    required this.descriptionEn,
    this.isPopular = false,
    this.isCustom = false,
  });

  /// The 6 authoritative tiers from Mujeeb_24_Pricing_Contract_v2.0.md and backend migration 000076.
  static const List<PricingPlan> canonicalPlans = [
    PricingPlan(
      id: '00000000-0000-0000-0000-00000000a101',
      code: 'starter',
      nameAr: 'بداية',
      nameEn: 'Starter',
      priceYer: 4000,
      aiReplyLimit: 50,
      aiCatalogLimit: 20,
      includedChannels: 1,
      channelCeiling: 1,
      seatLimit: 1,
      internalAiCostBudgetYer: 500,
      descriptionAr: 'للبائع المنزلي أو إثبات مبيعات الرد الآلي للعملاء',
      descriptionEn: 'For home businesses and early AI sales validation',
    ),
    PricingPlan(
      id: '00000000-0000-0000-0000-00000000a102',
      code: 'basic',
      nameAr: 'متجر',
      nameEn: 'Basic',
      priceYer: 6500,
      aiReplyLimit: 200,
      aiCatalogLimit: 60,
      includedChannels: 1,
      channelCeiling: 1,
      seatLimit: 2,
      internalAiCostBudgetYer: 1000,
      descriptionAr: 'أول باقة تشغيل منتظم لمتجر صغير بكتالوج محدد',
      descriptionEn: 'Regular operation for small stores with limited catalog',
    ),
    PricingPlan(
      id: '00000000-0000-0000-0000-00000000a103',
      code: 'growth',
      nameAr: 'نمو',
      nameEn: 'Growth',
      priceYer: 10000,
      aiReplyLimit: 500,
      aiCatalogLimit: 200,
      includedChannels: 1,
      channelCeiling: 2,
      seatLimit: 3,
      internalAiCostBudgetYer: 2000,
      isPopular: true,
      descriptionAr:
          'للتاجر المعتمد على مجيب يومياً مع كتالوج أوسع وسقف قناتين',
      descriptionEn:
          'For expanding stores with broader catalog and 2 channels ceiling',
    ),
    PricingPlan(
      id: '00000000-0000-0000-0000-00000000a104',
      code: 'pro',
      nameAr: 'احتراف',
      nameEn: 'Pro',
      priceYer: 16000,
      aiReplyLimit: 1200,
      aiCatalogLimit: 600,
      includedChannels: 1,
      channelCeiling: 3,
      seatLimit: 5,
      internalAiCostBudgetYer: 4000,
      descriptionAr: 'لمتجر قائم لديه حجم محادثات أعلى وفريق عمل',
      descriptionEn:
          'For established stores with higher chat volume and team seats',
    ),
    PricingPlan(
      id: '00000000-0000-0000-0000-00000000a105',
      code: 'business',
      nameAr: 'أعمال',
      nameEn: 'Business',
      priceYer: 25000,
      aiReplyLimit: 3000,
      aiCatalogLimit: 1500,
      includedChannels: 1,
      channelCeiling: 5,
      seatLimit: 10,
      internalAiCostBudgetYer: 7500,
      descriptionAr: 'للحجم المحلي الأعلى قبل العقد المخصص وسقف خمس قنوات',
      descriptionEn:
          'For highest local commercial scale and 5 channels ceiling',
    ),
    PricingPlan(
      id: 'enterprise',
      code: 'enterprise',
      nameAr: 'مؤسسات / وكالات',
      nameEn: 'Enterprise',
      priceYer: 0,
      aiReplyLimit: 0,
      aiCatalogLimit: 0,
      includedChannels: 0,
      channelCeiling: 0,
      seatLimit: 0,
      internalAiCostBudgetYer: 0,
      isCustom: true,
      descriptionAr: 'سعة مخصصة ودعم فني خاص واتفاقية مستوى خدمة (SLA)',
      descriptionEn:
          'Custom volume, dedicated support and Service Level Agreement',
    ),
  ];

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    // Look up canonical metadata for enriched descriptions
    final canonical = canonicalPlans.firstWhere(
      (p) => p.code.toLowerCase() == code.toLowerCase(),
      orElse: () => canonicalPlans.first,
    );

    return PricingPlan(
      id: json['id'] as String? ?? canonical.id,
      code: code,
      nameAr: canonical.nameAr,
      nameEn: json['display_name'] as String? ?? canonical.nameEn,
      priceYer: (json['price_yer'] as num?)?.toInt() ?? canonical.priceYer,
      billingInterval: json['billing_interval'] as String? ?? 'MONTH',
      aiReplyLimit:
          (json['ai_reply_limit'] as num?)?.toInt() ?? canonical.aiReplyLimit,
      aiCatalogLimit:
          (json['ai_catalog_limit'] as num?)?.toInt() ??
          canonical.aiCatalogLimit,
      includedChannels:
          (json['included_channel_limit'] as num?)?.toInt() ??
          (json['channel_limit'] as num?)?.toInt() ??
          canonical.includedChannels,
      channelCeiling:
          (json['channel_ceiling'] as num?)?.toInt() ??
          canonical.channelCeiling,
      seatLimit: (json['seat_limit'] as num?)?.toInt() ?? canonical.seatLimit,
      internalAiCostBudgetYer:
          (json['internal_ai_cost_budget_yer'] as num?)?.toInt() ??
          canonical.internalAiCostBudgetYer,
      descriptionAr: canonical.descriptionAr,
      descriptionEn: canonical.descriptionEn,
      isPopular: canonical.isPopular,
      isCustom: code.toLowerCase() == 'enterprise',
    );
  }
}

/// Payment method definition matching backend enum: CASH, BANK_TRANSFER, MOBILE_MONEY, OTHER.
class ManualPaymentMethod {
  final String code;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final String noteAr;

  const ManualPaymentMethod({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.noteAr,
  });

  static const List<ManualPaymentMethod> supportedMethods = [
    ManualPaymentMethod(
      code: 'BANK_TRANSFER',
      nameAr: 'تحويل بنكي',
      nameEn: 'Bank Transfer',
      icon: Icons.account_balance_rounded,
      noteAr: 'عبر بنك القطيبي، بنك البسيري، أو بنك الكريمي',
    ),
    ManualPaymentMethod(
      code: 'MOBILE_MONEY',
      nameAr: 'محفظة إلكترونية',
      nameEn: 'Mobile Money',
      icon: Icons.phone_android_rounded,
      noteAr: 'عبر كريمي إكسبرس أو محفظة جوالي',
    ),
    ManualPaymentMethod(
      code: 'CASH',
      nameAr: 'نقداً',
      nameEn: 'Cash',
      icon: Icons.payments_rounded,
      noteAr: 'تسليم يدوي لدى نقاط وممثلي خدمة مجيب',
    ),
    ManualPaymentMethod(
      code: 'OTHER',
      nameAr: 'وسيلة أخرى',
      nameEn: 'Other',
      icon: Icons.more_horiz_rounded,
      noteAr: 'أي وسيلة دفع أخرى معتمدة رسمياً',
    ),
  ];
}

/// Request payload to record a manual payment proof.
class ManualPaymentProofRequest {
  final String subscriptionId;
  final String businessId;
  final int amountYer;
  final String method; // CASH, BANK_TRANSFER, MOBILE_MONEY, OTHER
  final String reference;
  final String? notes;
  final String paidAt;

  const ManualPaymentProofRequest({
    required this.subscriptionId,
    required this.businessId,
    required this.amountYer,
    required this.method,
    required this.reference,
    this.notes,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() => {
    'amount_yer': amountYer,
    'method': method,
    'reference': reference,
    'paid_at': paidAt,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}
