import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Stub crash reporting — replaces Crashlytics when Firebase is not configured.
/// All methods are no-ops so callers can fire-and-forget.
class CrashReporting {
  /// Reflect the current auth state into crash reporting.
  /// Call after sign-in, org switch, or restore-from-storage.
  static Future<void> applyFromAuth(AuthService auth) async {
    // No-op without Firebase Crashlytics
  }

  /// Clear identity on sign-out.
  static Future<void> clear() async {
    // No-op without Firebase Crashlytics
  }
}
