import 'package:flutter/foundation.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';

/// State management Provider for Phase 2 Merchant operations
class MerchantProvider extends ChangeNotifier {
  final MerchantRepository merchantRepository;

  DashboardOverview? _dashboardOverview;
  Business? _businessProfile;
  BusinessPolicy? _businessPolicy;
  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;
  List<Message> _messages = [];
  List<CannedReply> _cannedReplies = [];

  bool _isLoadingDashboard = false;
  bool _isLoadingBusiness = false;
  bool _isLoadingPolicy = false;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isPerformingAction = false;

  String? _dashboardError;
  bool _dashboardRequiresLogin = false;
  String? _businessError;
  String? _policyError;
  String? _conversationsError;
  String? _messagesError;
  String? _actionError;
  String? _lastRequestId;

  // Conversations Filter State
  String _conversationChannelFilter = 'all';
  String _conversationStateFilter = 'all';
  String _conversationOwnershipFilter = 'all';
  String _conversationSearchQuery = '';

  MerchantProvider({required this.merchantRepository});

  DashboardOverview? get dashboardOverview => _dashboardOverview;
  Business? get businessProfile => _businessProfile;
  BusinessPolicy? get businessPolicy => _businessPolicy;
  List<Conversation> get conversations => _conversations;
  Conversation? get selectedConversation => _selectedConversation;
  List<Message> get messages => _messages;
  List<CannedReply> get cannedReplies => _cannedReplies;

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingBusiness => _isLoadingBusiness;
  bool get isLoadingPolicy => _isLoadingPolicy;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isPerformingAction => _isPerformingAction;

  String? get dashboardError => _dashboardError;
  bool get dashboardRequiresLogin => _dashboardRequiresLogin;
  String? get businessError => _businessError;
  String? get policyError => _policyError;
  String? get conversationsError => _conversationsError;
  String? get messagesError => _messagesError;
  String? get actionError => _actionError;
  String? get lastRequestId => _lastRequestId;

  String get conversationChannelFilter => _conversationChannelFilter;
  String get conversationStateFilter => _conversationStateFilter;
  String get conversationOwnershipFilter => _conversationOwnershipFilter;
  String get conversationSearchQuery => _conversationSearchQuery;

  int get activeConversationFiltersCount {
    int count = 0;
    if (_conversationChannelFilter != 'all') count++;
    if (_conversationStateFilter != 'all') count++;
    if (_conversationOwnershipFilter != 'all') count++;
    if (_conversationSearchQuery.trim().isNotEmpty) count++;
    return count;
  }

  /// Filtered conversations considering search query, state, and ownership
  List<Conversation> get filteredConversations {
    return _conversations.where((c) {
      if (_conversationSearchQuery.trim().isNotEmpty) {
        final q = _conversationSearchQuery.trim().toLowerCase();
        final name = (c.customer.displayName ?? '').toLowerCase();
        final id = c.id.toLowerCase();
        final custId = c.customer.id.toLowerCase();
        final matchesLabels = c.labels.any((l) => l.toLowerCase().contains(q));
        if (!name.contains(q) &&
            !id.contains(q) &&
            !custId.contains(q) &&
            !matchesLabels) {
          return false;
        }
      }

      if (_conversationStateFilter != 'all' &&
          c.state != _conversationStateFilter) {
        return false;
      }

      if (_conversationOwnershipFilter == 'assigned' &&
          (c.assignment == null || c.ownership == 'none' || c.ownership == 'unassigned')) {
        return false;
      }
      if (_conversationOwnershipFilter == 'unassigned' &&
          (c.assignment != null && c.ownership != 'none' && c.ownership != 'unassigned')) {
        return false;
      }

      return true;
    }).toList();
  }

  void clearErrors() {
    _dashboardError = null;
    _dashboardRequiresLogin = false;
    _businessError = null;
    _policyError = null;
    _conversationsError = null;
    _messagesError = null;
    _actionError = null;
    _lastRequestId = null;
    notifyListeners();
  }

  /// Load Dashboard Overview
  Future<void> loadDashboardOverview(String businessId) async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    _dashboardRequiresLogin = false;
    notifyListeners();

    try {
      final overview = await merchantRepository.getDashboardOverview(businessId);
      _dashboardOverview = overview;
      _lastRequestId = null;
    } on ApiErrorEnvelope catch (e) {
      // Never render stale business metrics after an unauthorized response.
      _dashboardOverview = null;
      _lastRequestId = e.requestId;
      final code = e.error.code.toLowerCase();
      final serverMessage = e.error.message.toLowerCase();
      _dashboardRequiresLogin = e.statusCode == 401 ||
          code.contains('unauthorized') ||
          code.contains('invalid_token') ||
          code.contains('token_expired') ||
          serverMessage.contains('invalid access token');
      final safeArabicMessage = e.error.message.length <= 160 &&
          RegExp(r'[ء-ي]').hasMatch(e.error.message);
      _dashboardError = _dashboardRequiresLogin
          ? 'انتهت صلاحية جلسة الدخول. سجّل دخولك من جديد.'
          : safeArabicMessage
              ? e.error.message
              : 'تعذر جلب بيانات النشاط حاليًا. حاول مرة أخرى.';
    } on NetworkException {
      _dashboardOverview = null;
      _dashboardError = 'تعذر الاتصال بالخادم. تحقق من الإنترنت ثم أعد المحاولة.';
    } catch (_) {
      _dashboardOverview = null;
      _dashboardError = 'تعذر تحميل لوحة النشاط. حاول مرة أخرى.';
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Load Business Profile
  Future<void> loadBusinessProfile(String businessId) async {
    _isLoadingBusiness = true;
    _businessError = null;
    notifyListeners();

    try {
      final profile = await merchantRepository.getBusinessProfile(businessId);
      _businessProfile = profile;
    } on ApiErrorEnvelope catch (e) {
      _businessError = e.error.message;
      _lastRequestId = e.requestId;
    } catch (e) {
      _businessError = e.toString();
    } finally {
      _isLoadingBusiness = false;
      notifyListeners();
    }
  }

  /// Update Business Profile
  Future<bool> updateBusinessProfile({
    required String businessId,
    String? name,
    String? defaultCurrency,
    String? locale,
    String? timezone,
  }) async {
    _isPerformingAction = true;
    _businessError = null;
    notifyListeners();

    try {
      final updated = await merchantRepository.updateBusinessProfile(
        businessId: businessId,
        name: name,
        defaultCurrency: defaultCurrency,
        locale: locale,
        timezone: timezone,
        ifMatch: _businessProfile?.resourceVersion,
      );
      _businessProfile = updated;
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _businessError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _businessError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Load Business Policy
  Future<void> loadBusinessPolicy(String businessId) async {
    _isLoadingPolicy = true;
    _policyError = null;
    notifyListeners();

    try {
      final policy = await merchantRepository.getBusinessPolicy(businessId);
      _businessPolicy = policy;
    } on ApiErrorEnvelope catch (e) {
      _policyError = e.error.message;
      _lastRequestId = e.requestId;
    } catch (e) {
      _policyError = e.toString();
    } finally {
      _isLoadingPolicy = false;
      notifyListeners();
    }
  }

  /// Update Business Policy
  Future<bool> updateBusinessPolicy({
    required String businessId,
    String? aiMode,
    bool? defaultHumanReview,
    bool? allowAutoReply,
    bool? allowAutoLeadCreation,
    bool? allowAutoTransactionDraft,
    bool? allowAutoConfirmation,
  }) async {
    _isPerformingAction = true;
    _policyError = null;
    notifyListeners();

    try {
      final updated = await merchantRepository.updateBusinessPolicy(
        businessId: businessId,
        aiMode: aiMode,
        defaultHumanReview: defaultHumanReview,
        allowAutoReply: allowAutoReply,
        allowAutoLeadCreation: allowAutoLeadCreation,
        allowAutoTransactionDraft: allowAutoTransactionDraft,
        allowAutoConfirmation: allowAutoConfirmation,
        ifMatch: _businessPolicy?.resourceVersion,
      );
      _businessPolicy = updated;
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _policyError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _policyError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  void setConversationChannelFilter(String businessId, String channel) {
    if (_conversationChannelFilter != channel) {
      _conversationChannelFilter = channel;
      notifyListeners();
      if (businessId.isNotEmpty) {
        loadConversations(businessId);
      }
    }
  }

  void setConversationStateFilter(String businessId, String state) {
    if (_conversationStateFilter != state) {
      _conversationStateFilter = state;
      notifyListeners();
      if (businessId.isNotEmpty) {
        loadConversations(businessId);
      }
    }
  }

  void setConversationOwnershipFilter(String businessId, String ownership) {
    if (_conversationOwnershipFilter != ownership) {
      _conversationOwnershipFilter = ownership;
      notifyListeners();
      if (businessId.isNotEmpty) {
        loadConversations(businessId);
      }
    }
  }

  void setConversationSearchQuery(String query) {
    _conversationSearchQuery = query;
    notifyListeners();
  }

  void clearConversationFilters(String businessId) {
    _conversationChannelFilter = 'all';
    _conversationStateFilter = 'all';
    _conversationOwnershipFilter = 'all';
    _conversationSearchQuery = '';
    notifyListeners();
    if (businessId.isNotEmpty) {
      loadConversations(businessId);
    }
  }

  /// Load Conversations
  Future<void> loadConversations(
    String businessId, {
    String? state,
    String? ownership,
    String? channel,
  }) async {
    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final effectiveState = state ??
          (_conversationStateFilter != 'all' ? _conversationStateFilter : null);
      final effectiveOwnership = ownership ??
          (_conversationOwnershipFilter != 'all'
              ? _conversationOwnershipFilter
              : null);
      final effectiveChannel = channel ??
          (_conversationChannelFilter != 'all'
              ? _conversationChannelFilter
              : null);

      final list = await merchantRepository.listConversations(
        businessId: businessId,
        state: effectiveState,
        ownership: effectiveOwnership,
        channel: effectiveChannel,
      );
      _conversations = list;
    } on ApiErrorEnvelope catch (e) {
      _conversationsError = e.error.message;
      _lastRequestId = e.requestId;
    } catch (e) {
      _conversationsError = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Select Conversation and load details & messages
  Future<void> selectConversation({
    required String businessId,
    required String conversationId,
  }) async {
    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      // Find or fetch conversation
      final conv = await merchantRepository.getConversation(
        businessId: businessId,
        conversationId: conversationId,
      );
      _selectedConversation = conv;

      // Mark as read in the background
      merchantRepository
          .markConversationRead(
            businessId: businessId,
            conversationId: conversationId,
            ifMatch: conv.resourceVersion,
          )
          .catchError((_) => conv);

      // Fetch messages
      final msgs = await merchantRepository.listMessages(
        businessId: businessId,
        conversationId: conversationId,
      );
      _messages = msgs;
    } on ApiErrorEnvelope catch (e) {
      _messagesError = e.error.message;
      _lastRequestId = e.requestId;
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send Message in conversation
  Future<bool> sendMessage({
    required String businessId,
    required String conversationId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final msg = await merchantRepository.sendMessage(
        businessId: businessId,
        conversationId: conversationId,
        text: text.trim(),
      );
      _messages.add(msg);
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Add private note
  Future<bool> addPrivateNote({
    required String businessId,
    required String conversationId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final note = await merchantRepository.addPrivateNote(
        businessId: businessId,
        conversationId: conversationId,
        text: text.trim(),
        ifMatch: _selectedConversation?.resourceVersion,
      );
      _messages.add(note);
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Assign conversation
  Future<bool> assignConversation({
    required String businessId,
    required String conversationId,
    required String assigneePrincipalId,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await merchantRepository.assignConversation(
        businessId: businessId,
        conversationId: conversationId,
        assigneePrincipalId: assigneePrincipalId,
        ifMatch: _selectedConversation?.resourceVersion,
      );
      _selectedConversation = updated;
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) _conversations[idx] = updated;
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Update conversation labels
  Future<bool> updateConversationLabels({
    required String businessId,
    required String conversationId,
    List<String>? add,
    List<String>? remove,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await merchantRepository.updateConversationLabels(
        businessId: businessId,
        conversationId: conversationId,
        add: add,
        remove: remove,
        ifMatch: _selectedConversation?.resourceVersion,
      );
      _selectedConversation = updated;
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) _conversations[idx] = updated;
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Update conversation state / priority / ai_mode
  Future<bool> updateConversation({
    required String businessId,
    required String conversationId,
    String? state,
    String? priority,
    String? ownership,
    String? aiModeOverride,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await merchantRepository.updateConversation(
        businessId: businessId,
        conversationId: conversationId,
        state: state,
        priority: priority,
        ownership: ownership,
        aiModeOverride: aiModeOverride,
        ifMatch: _selectedConversation?.resourceVersion,
      );
      _selectedConversation = updated;
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) _conversations[idx] = updated;
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Load canned replies
  Future<void> loadCannedReplies(String businessId) async {
    try {
      final replies = await merchantRepository.listCannedReplies(
        businessId: businessId,
      );
      _cannedReplies = replies;
      notifyListeners();
    } catch (_) {
      // Ignored silently or handled
    }
  }

  /// Send canned reply
  Future<bool> sendCannedReply({
    required String businessId,
    required String conversationId,
    required String cannedReplyId,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final msg = await merchantRepository.sendCannedReply(
        businessId: businessId,
        conversationId: conversationId,
        cannedReplyId: cannedReplyId,
        ifMatch: _selectedConversation?.resourceVersion,
      );
      _messages.add(msg);
      _isPerformingAction = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      _isPerformingAction = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = e.toString();
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }
}
