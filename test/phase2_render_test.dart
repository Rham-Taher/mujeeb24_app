import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/features/auth/presentation/login_screen.dart';
import 'package:mujeeb24_app/features/auth/presentation/splash_screen.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class MockAuthRepo extends AuthRepository {
  final bool shouldFail;
  MockAuthRepo({this.shouldFail = false}) : super(apiClient: ApiClient());

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    if (shouldFail) {
      throw ApiErrorEnvelope.fromRaw(
        code: 'INVALID_CREDENTIALS',
        message: 'بيانات الاعتماد غير متطابقة، يرجى التحقق من البريد وكلمة المرور',
        requestId: 'req_auth_err_8841',
        statusCode: 401,
      );
    }
    return AuthResponse(
      accessToken: 'test_token',
      tokenType: 'Bearer',
      expiresAt: '2026-10-15T00:00:00Z',
      isPlatformAdmin: false,
      principal: const Principal(
        principalId: 'p_1',
        displayName: 'Test User',
        email: 'test@example.com',
      ),
    );
  }
}

Future<void> captureWidgetScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filePath,
) async {
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Visual Capture Tests', () {
    testWidgets('Capture SplashScreen rendering', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: key,
            child: const SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 650));
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase2_splash.png');
      expect(File('docs/renders/phase2_splash.png').existsSync(), isTrue);
    });

    testWidgets('Capture LoginScreen default rendering', (tester) async {
      final key = GlobalKey();
      final authProvider = AuthProvider(
        authRepository: MockAuthRepo(),
        workspaceRepository: WorkspaceRepository(apiClient: ApiClient()),
      );

      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RepaintBoundary(
            key: key,
            child: LoginScreen(
              authProvider: authProvider,
              onLoginSuccess: () {},
              onNavigateToInvitation: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await captureWidgetScreenshot(tester, key, 'docs/renders/phase2_login.png');
      expect(File('docs/renders/phase2_login.png').existsSync(), isTrue);
    });

    testWidgets('Capture LoginScreen with error state', (tester) async {
      final key = GlobalKey();
      final authProvider = AuthProvider(
        authRepository: MockAuthRepo(shouldFail: true),
        workspaceRepository: WorkspaceRepository(apiClient: ApiClient()),
      );

      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RepaintBoundary(
            key: key,
            child: LoginScreen(
              authProvider: authProvider,
              onLoginSuccess: () {},
              onNavigateToInvitation: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      // Fill demo credentials
      await tester.tap(find.text('تعبئة سريعة'));
      await tester.pump(const Duration(milliseconds: 100));
      // Submit login
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pump(const Duration(milliseconds: 300));

      await captureWidgetScreenshot(tester, key, 'docs/renders/phase2_login_error.png');
      expect(File('docs/renders/phase2_login_error.png').existsSync(), isTrue);
    });
  });
}
