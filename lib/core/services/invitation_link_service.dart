import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for generating invitation links and sharing them
/// across mobile applications (WhatsApp, Facebook, Instagram, etc.).
class InvitationLinkService {
  /// Default web domain used for invitation landing pages
  static const String defaultWebBaseUrl = 'https://mujeeb24.com/accept-invite';

  /// Custom URI scheme for direct deep linking into the mobile app
  static const String appScheme = 'mujeeb24://invite';

  /// Builds a standard web invitation link with the given acceptance token
  static String buildWebInvitationUrl(
    String token, {
    String baseUrl = defaultWebBaseUrl,
  }) {
    final cleanToken = token.trim();
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['token'] = cleanToken;
    return uri.replace(queryParameters: params).toString();
  }

  /// Builds a custom deep link with the given acceptance token
  static String buildAppDeepLink(String token) {
    final cleanToken = token.trim();
    return '$appScheme?token=${Uri.encodeComponent(cleanToken)}';
  }

  /// Formats a complete, friendly invitation message in Arabic (with English notice)
  /// suitable for instant messaging and social media sharing.
  static String formatShareMessage({
    required String token,
    String? businessName,
    String? role,
    String? email,
  }) {
    final link = buildWebInvitationUrl(token);
    final buffer = StringBuffer();

    buffer.writeln('دعوة للانضمام إلى فريق مجيب 24');
    buffer.writeln();
    if (businessName != null && businessName.trim().isNotEmpty) {
      buffer.writeln('تمت دعوتك للانضمام إلى فريق: $businessName');
    } else {
      buffer.writeln('تمت دعوتك للانضمام إلى فريق العمل.');
    }

    if (role != null && role.trim().isNotEmpty) {
      buffer.writeln('الدور الوظيفي: $role');
    }
    buffer.writeln();
    buffer.writeln('للبدء وقبول الدعوة، يرجى الضغط على الرابط التالي:');
    buffer.writeln(link);
    buffer.writeln();
    buffer.writeln('يمكن قبول الدعوة من صفحة الويب، أو إدخال الرمز في التطبيق.');
    buffer.writeln('الرابط والرمز مخصصان للمدعو فقط؛ لا تشاركهما علنًا.');
    buffer.writeln();
    buffer.writeln('رمز الدعوة: $token');

    return buffer.toString();
  }

  /// Shares the invitation using the native system share sheet.
  /// On mobile devices, this allows sharing to WhatsApp, Facebook, Instagram,
  /// Telegram, SMS, Gmail, and any available app.
  static Future<bool> shareInvitation({
    required String token,
    String? businessName,
    String? role,
    String? email,
  }) async {
    final text = formatShareMessage(
      token: token,
      businessName: businessName,
      role: role,
      email: email,
    );

    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: 'دعوة للانضمام إلى فريق مجيب 24'),
      );
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error invoking native share: $e');
      return false;
    }
  }
}
