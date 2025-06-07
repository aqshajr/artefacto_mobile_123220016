import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../model/user_model.dart';

class AuthService {
  final String baseUrl =
      'https://artefacto-backend-749281711221.us-central1.run.app/api/auth';

  Future<void> _saveUserData({
    required String token,
    required bool isAdmin,
    required int userId,
    String? username,
    String? email,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setBool('isAdmin', isAdmin);
    await prefs.setInt('userId', userId);
    await prefs.setBool('isLoggedIn', true);
    if (username != null) await prefs.setString('username', username);
    if (email != null) await prefs.setString('email', email);
    if (profilePicture != null) {
      await prefs.setString('profilePicture', profilePicture);
    }

    await prefs.setInt('lastLoginTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final lastLoginTime = prefs.getInt('lastLoginTime') ?? 0;
      final token = prefs.getString('token');

      if (!isLoggedIn || token == null) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionAge = now - lastLoginTime;
      if (sessionAge > const Duration(days: 30).inMilliseconds) {
        await _clearUserData();
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/validate-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await prefs.setInt('lastLoginTime', now);
        return true;
      } else {
        await _clearUserData();
        return false;
      }
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'passwordConfirmation': passwordConfirmation,
      'role': 0,
    });
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final jsonData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final userModel = UserModel.fromJson(jsonData);
        if (userModel.status == 'sukses' && userModel.data?.token != null) {
          final user = userModel.data!.user!;
          final token = userModel.data!.token!;
          await _saveUserData(
            token: token,
            isAdmin: user.role ?? false,
            userId: user.id ?? 0,
            username: user.username,
            email: user.email,
            profilePicture: user.profilePicture,
          );
          return {
            'success': true,
            'data': userModel.data,
            'message': userModel.message ?? 'Registration successful',
          };
        } else {
          return {
            'success': false,
            'message': userModel.message ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              jsonData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final body = jsonEncode({'email': email, 'password': password});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userModel = UserModel.fromJson(jsonData);

        if (userModel.status == 'sukses' && userModel.data?.token != null) {
          final user = userModel.data!.user!;
          final token = userModel.data!.token!;

          await _saveUserData(
            token: token,
            isAdmin: user.role ?? false,
            userId: user.id ?? 0,
            username: user.username,
            email: user.email,
            profilePicture: user.profilePicture,
          );

          return {
            'success': true,
            'data': userModel.data,
            'message': userModel.message ?? 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message': userModel.message ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              jsonData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        try {
          await http.post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
        } catch (e) {
          print('Error notifying backend about logout: $e');
        }
      }
    } finally {
      await _clearUserData();
    }
  }

  Future<bool> isLoggedIn() async {
    return checkSession();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdmin') ?? false;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profilePicture');
  }
}
