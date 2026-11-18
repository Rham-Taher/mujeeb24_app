import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service managing device biometric authentication (Fingerprint / Face ID).
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Checks if biometric authentication is supported and enrolled on the device.
  Future<bool> isBiometricAvailable() async {
    try {
      if (kIsWeb) return false;
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the system biometric dialog to authenticate the user.
  Future<bool> authenticate({
    String localizedReason = 'سجّل دخولك بسرعة وأمان باستخدام البصمة',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
