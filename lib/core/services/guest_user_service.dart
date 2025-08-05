import 'package:shared_preferences/shared_preferences.dart';

class GuestUserService {
  static const String _guestSessionKey = 'guest_session_active';
  static const String _guestUserIdKey = 'guest_user_id';
  static const String _guestCreatedAtKey = 'guest_created_at';

  /// Check if user is currently in guest mode
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestSessionKey) ?? false;
  }

  /// Start a guest session
  static Future<void> startGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

    await prefs.setBool(_guestSessionKey, true);
    await prefs.setString(_guestUserIdKey, guestId);
    await prefs.setString(_guestCreatedAtKey, DateTime.now().toIso8601String());

    print('👤 GUEST: Guest session started with ID: $guestId');
  }

  /// End the current guest session
  static Future<void> endGuestSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_guestSessionKey);
    await prefs.remove(_guestUserIdKey);
    await prefs.remove(_guestCreatedAtKey);

    print('👤 GUEST: Guest session ended');
  }

  /// Get the current guest user ID
  static Future<String?> getGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestUserIdKey);
  }

  /// Get when the guest session was created
  static Future<DateTime?> getGuestCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final createdAtStr = prefs.getString(_guestCreatedAtKey);
    if (createdAtStr != null) {
      return DateTime.parse(createdAtStr);
    }
    return null;
  }

  /// Check if guest session is still valid (not expired)
  static Future<bool> isGuestSessionValid() async {
    final isGuest = await isGuestMode();
    if (!isGuest) return false;

    final createdAt = await getGuestCreatedAt();
    if (createdAt == null) return false;

    // Guest sessions are valid for 30 days
    final expiryDate = createdAt.add(const Duration(days: 30));
    final isValid = DateTime.now().isBefore(expiryDate);

    if (!isValid) {
      print('👤 GUEST: Guest session expired, cleaning up...');
      await endGuestSession();
    }

    return isValid;
  }

  /// Get guest user info for display
  static Future<Map<String, dynamic>> getGuestUserInfo() async {
    final guestId = await getGuestUserId();
    final createdAt = await getGuestCreatedAt();

    return {
      'id': guestId ?? 'unknown',
      'name': 'Guest User',
      'createdAt': createdAt,
      'isGuest': true,
    };
  }
}
