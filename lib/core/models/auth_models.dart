/// Data models for Authentication, Principals, Businesses, and Invitations
library;

class Principal {
  final String principalId;
  final String displayName;
  final String? email;

  const Principal({
    required this.principalId,
    required this.displayName,
    this.email,
  });

  factory Principal.fromJson(Map<String, dynamic> json) {
    return Principal(
      principalId: json['principal_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'principal_id': principalId,
    'display_name': displayName,
    if (email != null) 'email': email,
  };
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final String expiresAt;
  final bool isPlatformAdmin;
  final Principal principal;

  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.isPlatformAdmin,
    required this.principal,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresAt: json['expires_at'] as String? ?? '',
      isPlatformAdmin: json['is_platform_admin'] as bool? ?? false,
      principal: Principal.fromJson(
        json['principal'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'expires_at': expiresAt,
    'is_platform_admin': isPlatformAdmin,
    'principal': principal.toJson(),
  };
}

class Business {
  final String id;
  final String name;
  final String slug;
  final String? defaultCurrency;
  final String? locale;
  final String? timezone;
  final String? status;
  final String? resourceVersion;
  final String? verticalType;
  final String? createdAt;
  final String? updatedAt;

  const Business({
    required this.id,
    required this.name,
    required this.slug,
    this.defaultCurrency,
    this.locale,
    this.timezone,
    this.status,
    this.resourceVersion,
    this.verticalType,
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      defaultCurrency: json['default_currency'] as String?,
      locale: json['locale'] as String?,
      timezone: json['timezone'] as String?,
      status: json['status'] as String?,
      resourceVersion: json['resource_version'] as String?,
      verticalType: json['vertical_type'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    if (defaultCurrency != null) 'default_currency': defaultCurrency,
    if (locale != null) 'locale': locale,
    if (timezone != null) 'timezone': timezone,
    if (status != null) 'status': status,
    if (resourceVersion != null) 'resource_version': resourceVersion,
    if (verticalType != null) 'vertical_type': verticalType,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class BusinessMembership {
  final Business business;
  final List<String> permissions;
  final String? principalId;
  final String? role;
  final String? status;

  const BusinessMembership({
    required this.business,
    required this.permissions,
    this.principalId,
    this.role,
    this.status,
  });

  factory BusinessMembership.fromJson(Map<String, dynamic> json) {
    return BusinessMembership(
      business: Business.fromJson(
        json['business'] as Map<String, dynamic>? ?? {},
      ),
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      principalId: json['principal_id'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'business': business.toJson(),
    'permissions': permissions,
    if (principalId != null) 'principal_id': principalId,
    if (role != null) 'role': role,
    if (status != null) 'status': status,
  };
}

class PaginationPage {
  final String? nextCursor;
  final bool hasMore;

  const PaginationPage({this.nextCursor, required this.hasMore});

  factory PaginationPage.fromJson(Map<String, dynamic> json) {
    return PaginationPage(
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (nextCursor != null) 'next_cursor': nextCursor,
    'has_more': hasMore,
  };
}

class TeamInvitation {
  final String id;
  final String businessId;
  final String businessName;
  final String email;
  final String displayName;
  final String accountState; // 'new' or 'existing'
  final String status; // pending, accepted, revoked, expired
  final String role;
  final List<String> permissions;
  final String? acceptedAt;
  final String? acceptedBy;
  final String? invitedBy;
  final String createdAt;
  final String expiresAt;

  const TeamInvitation({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.email,
    required this.displayName,
    required this.accountState,
    this.status = 'pending',
    required this.role,
    required this.permissions,
    this.acceptedAt,
    this.acceptedBy,
    this.invitedBy,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isPending => status == 'pending';
  bool get isExpired {
    final end = DateTime.tryParse(expiresAt);
    return end == null || !end.isAfter(DateTime.now().toUtc());
  }
  bool get canBeAccepted => isPending && !isExpired;

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    return TeamInvitation(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      accountState: json['account_state'] as String? ?? 'new',
      status: json['status'] as String? ?? 'pending',
      role: json['role'] as String? ?? 'member',
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      acceptedAt: json['accepted_at'] as String?,
      acceptedBy: json['accepted_by'] as String?,
      invitedBy: json['invited_by'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'business_name': businessName,
    'email': email,
    'display_name': displayName,
    'account_state': accountState,
    'status': status,
    'role': role,
    'permissions': permissions,
    if (acceptedAt != null) 'accepted_at': acceptedAt,
    if (acceptedBy != null) 'accepted_by': acceptedBy,
    if (invitedBy != null) 'invited_by': invitedBy,
    'created_at': createdAt,
    'expires_at': expiresAt,
  };
}
