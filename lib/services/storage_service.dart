import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _opportunitiesKey = 'opportunities';
  static const String _applicationsKey = 'applications';
  static const String _messagesKey = 'messages';
  static const String _experiencesKey = 'experiences';
  static const String _notificationsKey = 'notifications';
  static const String _currentUserKey = 'current_user_id';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<void> saveData(String key, List<Map<String, dynamic>> data) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> getData(String key) async {
    final prefs = await _prefs;
    final data = prefs.getString(key);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> saveCurrentUser(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_currentUserKey, userId);
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_currentUserKey);
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await _prefs;
    await prefs.remove(_currentUserKey);
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  static String get usersKey => _usersKey;
  static String get opportunitiesKey => _opportunitiesKey;
  static String get applicationsKey => _applicationsKey;
  static String get messagesKey => _messagesKey;
  static String get experiencesKey => _experiencesKey;
  static String get notificationsKey => _notificationsKey;
}
