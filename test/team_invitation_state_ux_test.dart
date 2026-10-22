import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/team/team_invitation_presentation.dart';
import 'package:mujeeb24_app/features/auth/presentation/invitation_screen.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class _InviteRepo extends AuthRepository {
  final TeamInvitation invitation;
  _InviteRepo(this.invitation) : super(apiClient: ApiClient());

  @override
  Future<TeamInvitation> inspectInvitation({required String acceptanceToken}) async {
    return invitation;
  }
}

class _Workspace extends WorkspaceRepository {
  _Workspace() : super(apiClient: ApiClient());
  @override
  Future<List<BusinessMembership>> getAccessibleBusinesses({
    int limit = 25, String? cursor,
  }) async => [];
}

void main() {
  test('invitation status and expiry are read from the backend response', () {
    const data = {
      'id': 'inv-1', 'status': 'revoked',
      'expires_at': '2026-12-01T18:00:00Z',
      'business_id': 'b1', 'business_name': 'النشاط',
      'email': 'staff@example.test', 'display_name': 'موظف',
      'role': 'agent',
    };
    final invite = TeamInvitation.fromJson(data);
    expect(invite.canBeAccepted, isFalse);
    expect(invite.status, 'revoked');
    expect(TeamInvitation.fromJson({...data, 'status': 'pending'})
      .canBeAccepted, isTrue);
    expect(TeamInvitation.fromJson({
      ...data, 'status': 'pending', 'expires_at': '2020-01-01T00:00:00Z',
    }).canBeAccepted, isFalse);
  });

  test('specific account and seat errors are Arabic and redact server SQL', () {
    final seat = ApiErrorEnvelope.fromRaw(
      code: 'invalid_state_transition',
      message: 'The subscription has no available employee seat.',
      statusCode: 409,
    );
    final message = invitationErrorMessage(seat, resend: false);
    expect(message, contains('مقاعد'));
    expect(message, isNot(contains('invalid_state_transition')));
    final storage = ApiErrorEnvelope.fromRaw(
      code: 'external_dependency_unavailable',
      message: 'Team invitation could not be saved. Please contact support with the request ID.',
      statusCode: 503,
    );
    final storageMessage = invitationErrorMessage(storage, resend: true);
    expect(storageMessage, contains('الخادم'));
    expect(storageMessage, isNot(contains('SQL')));
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('revoked invite never displays password or create account at width $width',
      (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repo = _InviteRepo(const TeamInvitation(
        id: '1', businessId: 'b', businessName: 'مجيب',
        email: 'employee@example.test', displayName: 'موظف',
        accountState: 'new', role: 'agent', permissions: [],
        status: 'revoked', createdAt: '2026-10-01T00:00:00Z',
        expiresAt: '2026-12-01T00:00:00Z',
      ));
      final provider = AuthProvider(
        authRepository: repo, workspaceRepository: _Workspace());
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: InvitationScreen(
          authProvider: provider,
          initialToken: 'test-token',
          onBackToLogin: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('ألغيت الدعوة'), findsOneWidget);
      expect(find.text('إنشاء الحساب وقبول الدعوة'), findsNothing);
      expect(find.textContaining('غير قابلة للقبول'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
