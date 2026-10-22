import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Service that listens for incoming deep links and extracts invitation tokens.
/// Supports both custom schemes (e.g. `mujeeb24://invite?token=...`)
/// and universal/app links (e.g. `https://mujeeb24.com/accept-invite?token=...`).
class DeepLinkService {
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  /// Initializes listening for initial and incoming deep links
  Future<void> init({
    required void Function(String token) onInvitationReceived,
  }) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        final token = extractInvitationToken(initialUri);
        if (token != null) {
          onInvitationReceived(token);
        }
      }
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }

    try {
      _sub = _appLinks.uriLinkStream.listen(
        (uri) {
          final token = extractInvitationToken(uri);
          if (token != null) {
            onInvitationReceived(token);
          }
        },
        onError: (err) {
          debugPrint('DeepLinkService stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('DeepLinkService stream listen error: $e');
    }
  }

  /// Extracts invitation token from Uri query parameters or path segments
  static String? extractInvitationToken(Uri uri) {
    // 1. Check query parameter `token`
    if (uri.scheme != 'mujeeb24' && uri.scheme != 'https') return null;
    if (uri.scheme == 'https' && uri.host != 'mujeeb24.com') return null;
    if (uri.scheme == 'mujeeb24' && uri.host != 'invite') return null;

    if (uri.scheme == 'https' &&
        uri.path != '/accept-invite' && uri.path != '/auth/accept-invite') {
      return null;
    }
    final tokenParam = uri.queryParameters['token'];
    if (tokenParam != null && tokenParam.trim().isNotEmpty) {
      return tokenParam.trim();
    }

    // 2. Check path segments (e.g. /invite/inv_token_here)
    final segments = uri.pathSegments;
    final inviteIndex = segments.indexOf('invite');
    if (inviteIndex != -1 && inviteIndex + 1 < segments.length) {
      final pathToken = segments[inviteIndex + 1];
      if (pathToken.trim().isNotEmpty) {
        return pathToken.trim();
      }
    }

    // 3. Fallback: if host is invite and path has token
    if (uri.host == 'invite' && segments.isNotEmpty) {
      return segments.first.trim();
    }

    return null;
  }

  void dispose() {
    _sub?.cancel();
  }
}
