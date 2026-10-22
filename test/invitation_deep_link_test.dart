import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/services/deep_link_service.dart';
import 'package:mujeeb24_app/core/services/invitation_link_service.dart';
import 'package:mujeeb24_app/features/auth/presentation/invitation_screen.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class FakeInvitationAuthRepository extends AuthRepository {
  FakeInvitationAuthRepository() : super(apiClient: ApiClient());

  @override
  Future<TeamInvitation> inspectInvitation({
    required String acceptanceToken,
  }) async {
    return const TeamInvitation(
      id: 'inv_1',
      businessId: 'biz_1',
      businessName: 'متجر الأفق الرقمي',
      email: 'invitee@example.com',
      displayName: 'مستخدم جديد',
      role: 'agent',
      permissions: ['messages.read'],
      createdAt: '2026-10-20T00:00:00Z',
      accountState: 'new',
      expiresAt: '2026-11-01T00:00:00Z',
    );
  }
}

class FakeWorkspaceRepository extends WorkspaceRepository {
  FakeWorkspaceRepository() : super(apiClient: ApiClient());

  @override
  Future<List<BusinessMembership>> getAccessibleBusinesses({
    int limit = 25,
    String? cursor,
  }) async => [];
}

void main() {
  group('InvitationLinkService Tests', () {
    test('buildWebInvitationUrl creates correct https url with token', () {
      const token = 'tok_test_123456';
      final url = InvitationLinkService.buildWebInvitationUrl(token);
      expect(url, 'https://mujeeb24.com/accept-invite?token=tok_test_123456');
    });

    test('buildAppDeepLink creates correct custom scheme url', () {
      const token = 'tok_test_123456';
      final url = InvitationLinkService.buildAppDeepLink(token);
      expect(url, 'mujeeb24://invite?token=tok_test_123456');
    });

    test('formatShareMessage includes token, link and explanation text', () {
      const token = 'tok_magic_789';
      final message = InvitationLinkService.formatShareMessage(
        token: token,
        businessName: 'متجر الأفق',
        role: 'مسؤول نشاط',
      );

      expect(message.contains(token), isTrue);
      expect(
        message.contains('https://mujeeb24.com/accept-invite?token=tok_magic_789'),
        isTrue,
      );
      expect(message.contains('متجر الأفق'), isTrue);
      expect(message.contains('مسؤول نشاط'), isTrue);
      expect(message.contains('يمكن قبول الدعوة من صفحة الويب'), isTrue);
    });
  });

  group('DeepLinkService URI Extraction Tests', () {
    test('extracts token from standard https web link with query param', () {
      final uri = Uri.parse('https://mujeeb24.com/accept-invite?token=inv_abc_123');
      final token = DeepLinkService.extractInvitationToken(uri);
      expect(token, 'inv_abc_123');
    });

    test('extracts token from custom app scheme with query param', () {
      final uri = Uri.parse('mujeeb24://invite?token=inv_custom_scheme');
      final token = DeepLinkService.extractInvitationToken(uri);
      expect(token, 'inv_custom_scheme');
    });

    test('extracts token from path segment /invite/inv_path_123', () {
      // Legacy paths are not valid accepting routes on the current website.
      final uri = Uri.parse('https://mujeeb24.com/invite/inv_path_123');
      final token = DeepLinkService.extractInvitationToken(uri);
      expect(token, isNull);
    });

    test('returns null for unrelated uri', () {
      final uri = Uri.parse('https://mujeeb24.com/home');
      final token = DeepLinkService.extractInvitationToken(uri);
      expect(token, isNull);
    });
  });

  group('InvitationScreen Deep Link Integration Tests', () {
    testWidgets(
      'InvitationScreen with initialToken auto-populates and inspects token',
      (tester) async {
        final authRepo = FakeInvitationAuthRepository();
        final authProvider = AuthProvider(
          authRepository: authRepo,
          workspaceRepository: FakeWorkspaceRepository(),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar')],
            locale: const Locale('ar'),
            home: InvitationScreen(
              authProvider: authProvider,
              initialToken: 'inv_deep_link_999',
              onBackToLogin: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify token was auto-populated
        expect(find.text('inv_deep_link_999'), findsOneWidget);
        // Verify auto-inspection fetched and displayed the invitation details
        expect(find.text('متجر الأفق الرقمي'), findsOneWidget);
        expect(find.text('invitee@example.com'), findsOneWidget);
      },
    );
  });
}
