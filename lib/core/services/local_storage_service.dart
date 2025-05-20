import 'package:shared_preferences/shared_preferences.dart';

abstract class ILocalStorageService {
  Future<bool> saveUserId(String userId);
  Future<bool> saveUserEmail(String userEmail);
  Future<bool> saveUserName(String name);
  Future<bool> saveUserPhotoUrl(String? userPic);
  Future<bool> saveUserAtUsername(String? atUsername);
  Future<String?> getUserId();
  Future<String?> getUserEmail();
  Future<String?> getUserName();
  Future<String?> getUserPhotoUrl();
  Future<String?> getUserAtUsername();
  Future<void> clearUserData();
}

class LocalStorageServiceImpl implements ILocalStorageService {
  // Claves
  static const String _kUserIdKey = "USER_ID_KEY";
  static const String _kUserEmailKey = "USER_EMAIL_KEY";
  static const String _kUserNameKey = "USER_NAME_KEY"; // Para el nombre real
  static const String _kUserAtUsernameKey =
      "USER_AT_USERNAME_KEY"; // Para el @username
  static const String _kUserPhotoUrlKey = "USER_PHOTO_URL_KEY";

  // Obtiene la instancia de SharedPreferences
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Guarda el ID del usuario
  @override
  Future<bool> saveUserId(String userId) async {
    final prefs = await _getPrefs();
    return prefs.setString(_kUserIdKey, userId);
  }

  @override
  Future<bool> saveUserEmail(String userEmai) async {
    final prefs = await _getPrefs();
    return prefs.setString(_kUserEmailKey, userEmai);
  }

  @override
  Future<bool> saveUserName(String name) async {
    final prefs = await _getPrefs();
    return prefs.setString(_kUserNameKey, name);
  }

  @override
  Future<bool> saveUserPhotoUrl(String? photoUrl) async {
    final prefs = await _getPrefs();
    if (photoUrl != null) {
      return prefs.setString(_kUserPhotoUrlKey, photoUrl);
    } else {
      return prefs.remove(_kUserPhotoUrlKey);
    }
  }

  @override
  Future<bool> saveUserAtUsername(String? atUsername) async {
     final prefs = await _getPrefs();
    if (atUsername != null) {
      return prefs.setString(_kUserAtUsernameKey, atUsername);
    } else {
      return prefs.remove(_kUserAtUsernameKey); 
    }
  }

  @override
  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserIdKey);
  }

  @override
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserEmailKey);
  }

  @override
  Future<String?> getUserName() async { // Devuelve el nombre real
    final prefs = await _getPrefs();
    return prefs.getString(_kUserNameKey);
  }

  @override
  Future<String?> getUserAtUsername() async { // Devuelve el @username
    final prefs = await _getPrefs();
    return prefs.getString(_kUserAtUsernameKey);
  }

  @override
  Future<String?> getUserPhotoUrl() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserPhotoUrlKey);
  }

  @override
  Future<void> clearUserData() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
