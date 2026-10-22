import 'package:flutter/foundation.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/team/team_invitation_presentation.dart';
import '../../../core/models/team_audit_models.dart';
import '../../../core/team/team_audit_repository.dart';

/// Provider for managing state across Phase 7 modules:
/// - Team members list, role/permissions updates, member revocation (protecting owner)
/// - Team invitations list, issuance, resend, revocation
/// - Audit logs timeline, filters (actor, action, resource), and detailed inspection
class TeamAuditProvider extends ChangeNotifier {
  final TeamAuditRepository repository;

  TeamAuditProvider({required this.repository});

  // ==========================================
  // Global Action & Diagnostics State
  // ==========================================
  bool _isPerformingAction = false;
  String? _actionError;
  String? _lastRequestId;
  TeamInvitationCreated? _latestCreatedInvitation;

  bool get isPerformingAction => _isPerformingAction;
  String? get actionError => _actionError;
  String? get lastRequestId => _lastRequestId;
  TeamInvitationCreated? get latestCreatedInvitation =>
      _latestCreatedInvitation;

  void clearActionState() {
    _isPerformingAction = false;
    _actionError = null;
    _latestCreatedInvitation = null;
    notifyListeners();
  }

  // ==========================================
  // Team Members State
  // ==========================================
  List<TeamMember> _members = [];
  bool _isLoadingMembers = false;
  String? _membersError;
  String? _membersCursor;
  bool _hasMoreMembers = false;
  String _memberRoleFilter = 'all';
  String _memberStatusFilter = 'all';

  List<TeamMember> get members {
    return _members.where((m) {
      if (_memberRoleFilter != 'all' &&
          m.role.toLowerCase() != _memberRoleFilter.toLowerCase()) {
        return false;
      }
      if (_memberStatusFilter != 'all' &&
          m.status.toLowerCase() != _memberStatusFilter.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TeamMember> get rawMembers => _members;
  bool get isLoadingMembers => _isLoadingMembers;
  String? get membersError => _membersError;
  bool get hasMoreMembers => _hasMoreMembers;
  String get memberRoleFilter => _memberRoleFilter;
  String get memberStatusFilter => _memberStatusFilter;

  void setMemberFilters({String? role, String? status}) {
    if (role != null) _memberRoleFilter = role;
    if (status != null) _memberStatusFilter = status;
    notifyListeners();
  }

  Future<void> fetchMembers(String businessId, {bool refresh = false}) async {
    if (refresh) {
      _membersCursor = null;
      _hasMoreMembers = false;
    }

    _isLoadingMembers = true;
    _membersError = null;
    notifyListeners();

    try {
      final page = await repository.listTeamMembers(
        businessId: businessId,
        cursor: refresh ? null : _membersCursor,
      );

      if (refresh) {
        _members = page.items;
      } else {
        _members.addAll(page.items);
      }
      _membersCursor = page.pagination.nextCursor;
      _hasMoreMembers = page.pagination.hasMore;
      _lastRequestId = page.requestId;
    } on ApiErrorEnvelope catch (e) {
      _membersError = e.error.message;
      _lastRequestId = e.requestId;
    } on NetworkException catch (e) {
      _membersError = e.message;
    } catch (e) {
      _membersError = e.toString();
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<bool> updateMemberRole({
    required String businessId,
    required String principalId,
    required String role,
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await repository.updateTeamMemberRole(
        businessId: businessId,
        principalId: principalId,
        request: UpdateTeamMemberRoleRequest(role: role),
        ifMatch: ifMatch,
      );

      final index = _members.indexWhere((m) => m.principalId == principalId);
      if (index != -1) {
        _members[index] = updated;
      }
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<bool> updateMemberAccess({
    required String businessId,
    required String principalId,
    required String role,
    required List<String> permissions,
    String? ifMatch,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await repository.updateTeamMemberAccess(
        businessId: businessId,
        principalId: principalId,
        request: UpdateTeamMemberAccessRequest(
          role: role,
          permissions: permissions,
        ),
        ifMatch: ifMatch,
      );

      final index = _members.indexWhere((m) => m.principalId == principalId);
      if (index != -1) {
        _members[index] = updated;
      }
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<bool> revokeMember({
    required String businessId,
    required String principalId,
    String? ifMatch,
  }) async {
    // Contract safety rule: Cannot revoke active owner
    final member = _members.firstWhere(
      (m) => m.principalId == principalId,
      orElse: () => const TeamMember(
        principalId: '',
        email: '',
        displayName: '',
        role: '',
        permissions: [],
        status: '',
      ),
    );

    if (member.isOwner) {
      _actionError = 'لا يمكن إلغاء عضوية المالك الرئيسي وفقًا لقواعد العقد';
      notifyListeners();
      return false;
    }

    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await repository.revokeTeamMember(
        businessId: businessId,
        principalId: principalId,
        ifMatch: ifMatch,
      );

      final index = _members.indexWhere((m) => m.principalId == principalId);
      if (index != -1) {
        _members[index] = updated;
      }
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Team Invitations State
  // ==========================================
  List<TeamInvitationDetails> _invitations = [];
  bool _isLoadingInvitations = false;
  String? _invitationsError;
  String? _invitationsCursor;
  bool _hasMoreInvitations = false;
  String _invitationStatusFilter = 'all';

  List<TeamInvitationDetails> get invitations {
    if (_invitationStatusFilter == 'all') return _invitations;
    return _invitations
        .where((inv) =>
            inv.status.toLowerCase() == _invitationStatusFilter.toLowerCase())
        .toList();
  }

  List<TeamInvitationDetails> get rawInvitations => _invitations;
  bool get isLoadingInvitations => _isLoadingInvitations;
  String? get invitationsError => _invitationsError;
  bool get hasMoreInvitations => _hasMoreInvitations;
  String get invitationStatusFilter => _invitationStatusFilter;

  void setInvitationStatusFilter(String status) {
    _invitationStatusFilter = status;
    notifyListeners();
  }

  Future<void> fetchInvitations(String businessId, {bool refresh = false}) async {
    if (refresh) {
      _invitationsCursor = null;
      _hasMoreInvitations = false;
    }

    _isLoadingInvitations = true;
    _invitationsError = null;
    notifyListeners();

    try {
      final page = await repository.listTeamInvitations(
        businessId: businessId,
        cursor: refresh ? null : _invitationsCursor,
      );

      if (refresh) {
        _invitations = page.items;
      } else {
        _invitations.addAll(page.items);
      }
      _invitationsCursor = page.pagination.nextCursor;
      _hasMoreInvitations = page.pagination.hasMore;
      _lastRequestId = page.requestId;
    } on ApiErrorEnvelope catch (e) {
      _invitationsError = e.error.message;
      _lastRequestId = e.requestId;
    } on NetworkException catch (e) {
      _invitationsError = e.message;
    } catch (e) {
      _invitationsError = e.toString();
    } finally {
      _isLoadingInvitations = false;
      notifyListeners();
    }
  }

  Future<TeamInvitationCreated?> createInvitation({
    required String businessId,
    required CreateTeamInvitationRequest request,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    _latestCreatedInvitation = null;
    notifyListeners();

    try {
      final created = await repository.createTeamInvitation(
        businessId: businessId,
        request: request,
      );

      _latestCreatedInvitation = created;
      _invitations.insert(0, created.invitation);
      return created;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      return null;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return null;
    } catch (e) {
      _actionError = e.toString();
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<TeamInvitationCreated?> resendInvitation({
    required String businessId,
    required String invitationId,
    int? expiresInHours,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final resent = await repository.resendTeamInvitation(
        businessId: businessId,
        invitationId: invitationId,
        expiresInHours: expiresInHours,
      );

      _latestCreatedInvitation = resent;
      // Resend creates a new token and a NEW invitation ID.
      // Refresh records rather than mutating the previous invitation ID.
      await fetchInvitations(businessId, refresh: true);
      return resent;
    } on ApiErrorEnvelope catch (e) {
      _actionError = invitationErrorMessage(e, resend: true);
      _lastRequestId = e.requestId;
      return null;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return null;
    } catch (e) {
      _actionError = 'تعذر تجديد الدعوة. تحقق من الاتصال.';
      return null;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  Future<bool> revokeInvitation({
    required String businessId,
    required String invitationId,
  }) async {
    _isPerformingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      final revoked = await repository.revokeTeamInvitation(
        businessId: businessId,
        invitationId: invitationId,
      );

      final index = _invitations.indexWhere((inv) => inv.id == invitationId);
      if (index != -1) {
        _invitations[index] = revoked;
      }
      return true;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _actionError = e.message;
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isPerformingAction = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Audit Events State
  // ==========================================
  List<AuditEvent> _auditEvents = [];
  bool _isLoadingAuditEvents = false;
  String? _auditEventsError;
  String? _auditCursor;
  bool _hasMoreAuditEvents = false;

  AuditEvent? _selectedAuditEvent;
  bool _isLoadingAuditDetail = false;

  String _actorTypeFilter = 'all';
  String _actionFilter = 'all';
  String _resourceTypeFilter = 'all';

  List<AuditEvent> get auditEvents => _auditEvents;
  bool get isLoadingAuditEvents => _isLoadingAuditEvents;
  String? get auditEventsError => _auditEventsError;
  bool get hasMoreAuditEvents => _hasMoreAuditEvents;

  AuditEvent? get selectedAuditEvent => _selectedAuditEvent;
  bool get isLoadingAuditDetail => _isLoadingAuditDetail;

  String get actorTypeFilter => _actorTypeFilter;
  String get actionFilter => _actionFilter;
  String get resourceTypeFilter => _resourceTypeFilter;

  void setAuditFilters({
    String? actorType,
    String? action,
    String? resourceType,
  }) {
    if (actorType != null) _actorTypeFilter = actorType;
    if (action != null) _actionFilter = action;
    if (resourceType != null) _resourceTypeFilter = resourceType;
    notifyListeners();
  }

  Future<void> fetchAuditEvents(String businessId, {bool refresh = false}) async {
    if (refresh) {
      _auditCursor = null;
      _hasMoreAuditEvents = false;
    }

    _isLoadingAuditEvents = true;
    _auditEventsError = null;
    notifyListeners();

    try {
      final page = await repository.listAuditEvents(
        businessId: businessId,
        cursor: refresh ? null : _auditCursor,
        actorType: _actorTypeFilter != 'all' ? _actorTypeFilter : null,
        action: _actionFilter != 'all' ? _actionFilter : null,
        resourceType:
            _resourceTypeFilter != 'all' ? _resourceTypeFilter : null,
      );

      if (refresh) {
        _auditEvents = page.items;
      } else {
        _auditEvents.addAll(page.items);
      }
      _auditCursor = page.pagination.nextCursor;
      _hasMoreAuditEvents = page.pagination.hasMore;
      _lastRequestId = page.requestId;
    } on ApiErrorEnvelope catch (e) {
      _auditEventsError = e.error.message;
      _lastRequestId = e.requestId;
    } on NetworkException catch (e) {
      _auditEventsError = e.message;
    } catch (e) {
      _auditEventsError = e.toString();
    } finally {
      _isLoadingAuditEvents = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditEventDetail(
    String businessId,
    String auditEventId,
  ) async {
    _isLoadingAuditDetail = true;
    notifyListeners();

    try {
      final event = await repository.getAuditEvent(
        businessId: businessId,
        auditEventId: auditEventId,
      );
      _selectedAuditEvent = event;
    } on ApiErrorEnvelope catch (e) {
      _actionError = e.error.message;
      _lastRequestId = e.requestId;
    } on NetworkException catch (e) {
      _actionError = e.message;
    } catch (e) {
      _actionError = e.toString();
    } finally {
      _isLoadingAuditDetail = false;
      notifyListeners();
    }
  }
}
