import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  int _userId = 0;
  String? _username;
  String? _email;
  String? _profilePicture;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  int get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get profilePicture => _profilePicture;
  String? get token => _token;

  UserProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isAdmin = prefs.getBool('isAdmin') ?? false;
    _userId = prefs.getInt('userId') ?? 0;
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    _profilePicture = prefs.getString('profilePicture');
    _token = prefs.getString('token');

    final sessionValid = await _authService.checkSession();
    if (!sessionValid) {
      await logout();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result['success']) {
      await checkLoginStatus();
    }
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (result['success']) {
      await checkLoginStatus();
    }
    return result;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isAdmin = false;
    _userId = 0;
    _username = null;
    _email = null;
    _profilePicture = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (username != null) {
      _username = username;
      await prefs.setString('username', username);
    }
    if (email != null) {
      _email = email;
      await prefs.setString('email', email);
    }
    if (profilePicture != null) {
      _profilePicture = profilePicture;
      await prefs.setString('profilePicture', profilePicture);
    }

    notifyListeners();
  }
}
