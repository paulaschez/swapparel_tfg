import 'package:shared_preferences/shared_preferences.dart';


abstract class ILocalStorageService {
  Future<bool> saveUserId(String userId);
  Future<bool> saveUserEmail(String userEmail);
  Future<bool> saveUserName(String userName);
  Future<bool> saveUserPic(String userPic);
  Future<bool> saveUserDisplayName(String userDisplayName);
  Future<String?> getUserId();
  Future<String?> getUserEmail();
  Future<String?> getUserName();
  Future<String?> getUserPic();
  Future<String?> getUserDisplayName();
  Future<void> clearUserData(); 
}

class LocalStorageServiceImpl implements ILocalStorageService {
  // Claves
  static const String _userIdKey = "USERID_KEY"; 
  static const String _userNameKey = "USERNAME_KEY";
  static const String _userEmailKey = "USEREMAIL_KEY";
  static const String _userPicKey = "USERPIC_KEY";
  static const String _userDisplayNameKey = "USERDISPLAYNAME_KEY";

  // Obtiene la instancia de SharedPreferences 
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Guarda el ID del usuario
  @override
  Future<bool> saveUserId(String getUserId) async {
    final prefs = await _getPrefs();
    return prefs.setString(_userIdKey, getUserId);
  }

  @override
  Future<bool> saveUserEmail(String getUserEmail) async {
    final prefs = await _getPrefs();
    return prefs.setString(_userEmailKey, getUserEmail);
  }


  @override
  Future<bool> saveUserName(String getUserName) async {
    final prefs = await _getPrefs();
    return prefs.setString(_userNameKey, getUserName);
  }

  @override
  Future<bool> saveUserPic(String getUserPic) async { 
    final prefs = await _getPrefs();
    return prefs.setString(_userPicKey, getUserPic);
  }

  @override
  Future<bool> saveUserDisplayName(String getUserDisplayName) async { // Renombrado de 'saver' a 'save'
    final prefs = await _getPrefs();
    return prefs.setString(_userDisplayNameKey, getUserDisplayName);
  }

  @override
  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userIdKey);
  }

  @override
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userEmailKey);
  }

  @override
  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userNameKey);
  }

  @override
  Future<String?> getUserPic() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userPicKey);
  }

  @override
  Future<String?> getUserDisplayName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userDisplayNameKey);
  }  

  @override
  Future<void> clearUserData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPicKey);
    await prefs.remove(_userDisplayNameKey);
  }
  
  

}