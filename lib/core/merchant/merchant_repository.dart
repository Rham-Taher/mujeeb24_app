import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';

/// Merchant Repository implementing Phase 2 operations:
/// - GET /businesses/{business_id}/dashboard/overview
/// - GET /businesses/{business_id}/subscription
/// - GET /businesses/{business_id}
/// - PATCH /businesses/{business_id}
/// - GET /businesses/{business_id}/policy
/// - PATCH /businesses/{business_id}/policy
/// - GET /businesses/{business_id}/conversations
/// - GET /businesses/{business_id}/conversations/{conversation_id}
/// - PATCH /businesses/{business_id}/conversations/{conversation_id}
/// - GET /businesses/{business_id}/conversations/{conversation_id}/messages
/// - POST /businesses/{business_id}/conversations/{conversation_id}/messages
/// - POST /businesses/{business_id}/conversations/{conversation_id}/assign
/// - POST /businesses/{business_id}/conversations/{conversation_id}/labels
/// - POST /businesses/{business_id}/conversations/{conversation_id}/notes
/// - POST /businesses/{business_id}/conversations/{conversation_id}/read
/// - GET /businesses/{business_id}/canned-replies
/// - POST /businesses/{business_id}/conversations/{conversation_id}/canned-replies/{canned_reply_id}/send
class MerchantRepository {
  final ApiClient apiClient;

  MerchantRepository({required this.apiClient});

  String _generateIdempotencyKey(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// GET /businesses/{business_id}/dashboard/overview
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    final response = await apiClient.get(
      '/businesses/$businessId/dashboard/overview',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return DashboardOverview.fromJson(data);
  }

  /// GET /businesses/{business_id}/subscription
  Future<MerchantSubscriptionView> getBusinessSubscription(String businessId) async {
    final response = await apiClient.get(
      '/businesses/$businessId/subscription',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return MerchantSubscriptionView.fromJson(data);
  }

  /// GET /businesses/{business_id}
  Future<Business> getBusinessProfile(String businessId) async {
    final response = await apiClient.get(
      '/businesses/$businessId',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Business.fromJson(data);
  }

  /// PATCH /businesses/{business_id}
  Future<Business> updateBusinessProfile({
    required String businessId,
    String? name,
    String? defaultCurrency,
    String? locale,
    String? timezone,
    String? verticalType,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) {
      body['name'] = name.trim();
    }
    if (defaultCurrency != null) {
      body['default_currency'] = defaultCurrency.trim();
    }
    if (locale != null) {
      body['locale'] = locale.trim();
    }
    if (timezone != null) {
      body['timezone'] = timezone.trim();
    }
    if (verticalType != null) {
      body['vertical_type'] = verticalType.trim();
    }

    final headers = <String, String>{};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.patch(
      '/businesses/$businessId',
      body: body,
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Business.fromJson(data);
  }

  /// GET /businesses/{business_id}/policy
  Future<BusinessPolicy> getBusinessPolicy(String businessId) async {
    final response = await apiClient.get(
      '/businesses/$businessId/policy',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return BusinessPolicy.fromJson(data);
  }

  /// PATCH /businesses/{business_id}/policy
  Future<BusinessPolicy> updateBusinessPolicy({
    required String businessId,
    String? aiMode,
    bool? defaultHumanReview,
    bool? allowAutoReply,
    bool? allowAutoLeadCreation,
    bool? allowAutoTransactionDraft,
    bool? allowAutoConfirmation,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (aiMode != null) {
      body['ai_mode'] = aiMode;
    }
    if (defaultHumanReview != null) {
      body['default_human_review'] = defaultHumanReview;
    }
    if (allowAutoReply != null) {
      body['allow_auto_reply'] = allowAutoReply;
    }
    if (allowAutoLeadCreation != null) {
      body['allow_auto_lead_creation'] = allowAutoLeadCreation;
    }
    if (allowAutoTransactionDraft != null) {
      body['allow_auto_transaction_draft'] = allowAutoTransactionDraft;
    }
    if (allowAutoConfirmation != null) {
      body['allow_auto_confirmation'] = allowAutoConfirmation;
    }

    final headers = <String, String>{};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.patch(
      '/businesses/$businessId/policy',
      body: body,
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return BusinessPolicy.fromJson(data);
  }

  /// GET /businesses/{business_id}/conversations
  Future<List<Conversation>> listConversations({
    required String businessId,
    int limit = 25,
    String? cursor,
    String? state,
    String? ownership,
    String? channel,
    String? customerId,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    if (state != null && state.isNotEmpty) {
      query['state'] = state;
    }
    if (ownership != null && ownership.isNotEmpty) {
      query['ownership'] = ownership;
    }
    if (channel != null && channel.isNotEmpty) {
      query['channel'] = channel;
    }
    if (customerId != null && customerId.isNotEmpty) {
      query['customer_id'] = customerId;
    }

    final response = await apiClient.get(
      '/businesses/$businessId/conversations',
      queryParameters: query,
      requiresAuth: true,
    );
    final dataList = response['data'] as List<dynamic>? ?? [];
    return dataList
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /businesses/{business_id}/conversations/{conversation_id}
  Future<Conversation> getConversation({
    required String businessId,
    required String conversationId,
  }) async {
    final response = await apiClient.get(
      '/businesses/$businessId/conversations/$conversationId',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// PATCH /businesses/{business_id}/conversations/{conversation_id}
  Future<Conversation> updateConversation({
    required String businessId,
    required String conversationId,
    String? state,
    String? priority,
    String? ownership,
    String? aiModeOverride,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (state != null) body['state'] = state;
    if (priority != null) body['priority'] = priority;
    if (ownership != null) body['ownership'] = ownership;
    if (aiModeOverride != null) body['ai_mode_override'] = aiModeOverride;

    final headers = <String, String>{};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.patch(
      '/businesses/$businessId/conversations/$conversationId',
      body: body,
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// GET /businesses/{business_id}/conversations/{conversation_id}/messages
  Future<List<Message>> listMessages({
    required String businessId,
    required String conversationId,
    int limit = 50,
    String? cursor,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final response = await apiClient.get(
      '/businesses/$businessId/conversations/$conversationId/messages',
      queryParameters: query,
      requiresAuth: true,
    );
    final dataList = response['data'] as List<dynamic>? ?? [];
    return dataList
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/messages
  Future<Message> sendMessage({
    required String businessId,
    required String conversationId,
    required String text,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('msg'),
    };
    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/messages',
      body: {'text': text.trim()},
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Message.fromJson(data);
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/assign
  Future<Conversation> assignConversation({
    required String businessId,
    required String conversationId,
    required String assigneePrincipalId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('assign'),
    };
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/assign',
      body: {'assignee_principal_id': assigneePrincipalId.trim()},
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/labels
  Future<Conversation> updateConversationLabels({
    required String businessId,
    required String conversationId,
    List<String>? add,
    List<String>? remove,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (add != null && add.isNotEmpty) body['add'] = add;
    if (remove != null && remove.isNotEmpty) body['remove'] = remove;

    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('labels'),
    };
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/labels',
      body: body,
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/notes
  Future<Message> addPrivateNote({
    required String businessId,
    required String conversationId,
    required String text,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('note'),
    };
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/notes',
      body: {'text': text.trim()},
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Message.fromJson(data);
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/read
  Future<Conversation> markConversationRead({
    required String businessId,
    required String conversationId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? _generateIdempotencyKey('read'),
    };
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/read',
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// GET /businesses/{business_id}/canned-replies
  Future<List<CannedReply>> listCannedReplies({
    required String businessId,
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      '/businesses/$businessId/canned-replies',
      queryParameters: {'limit': limit},
      requiresAuth: true,
    );
    final dataList = response['data'] as List<dynamic>? ?? [];
    return dataList
        .map((e) => CannedReply.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /businesses/{business_id}/conversations/{conversation_id}/canned-replies/{canned_reply_id}/send
  Future<Message> sendCannedReply({
    required String businessId,
    required String conversationId,
    required String cannedReplyId,
    String? ifMatch,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Idempotency-Key':
          idempotencyKey ?? _generateIdempotencyKey('canned_reply'),
    };
    if (ifMatch != null && ifMatch.isNotEmpty) {
      headers['If-Match'] = ifMatch;
    }

    final response = await apiClient.post(
      '/businesses/$businessId/conversations/$conversationId/canned-replies/$cannedReplyId/send',
      headers: headers,
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Message.fromJson(data);
  }
}
