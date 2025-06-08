import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:artefacto/utils/secure_storage.dart';

class AuthService {
  final String baseUrl =
      'https://artefacto-backend-749281711221.us-central1.run.app/api/auth';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> _saveUserData({
    required String token,
    required bool isAdmin,
    required int userId,
    String? username,
    String? email,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save JWT token to SharedPreferences as PRIMARY storage for 24h session
    await _saveTokenToPrefs(token);

    // Also try to save to SecureStorage as backup (might fail on some devices)
    try {
      await SecureStorage.setToken(token);
      print('Token saved to both SharedPreferences and SecureStorage');
    } catch (e) {
      print('SecureStorage failed, using SharedPreferences only: $e');
    }

    final expiryTime =
        DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    await prefs.setInt('tokenExpiryTime', expiryTime);

    // Save user data
    await prefs.setBool('isAdmin', isAdmin);
    await prefs.setInt('userId', userId);
    await prefs.setBool('isLoggedIn', true);
    if (username != null) await prefs.setString('username', username);
    if (email != null) await prefs.setString('email', email);
    if (profilePicture != null) {
      await prefs.setString('profilePicture', profilePicture);
    }

    print(
        'User data saved successfully. Token expires at: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');

    // Verify token was saved
    final savedToken = await getToken();
    print('Token verification - saved: ${savedToken != null ? 'YES' : 'NO'}');
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStorage.deleteToken();
    await _clearTokenFromPrefs();
    await prefs.clear();
    print('User data cleared');
  }

  Future<String?> getToken() async {
    // Check if token is expired first
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = prefs.getInt('tokenExpiryTime');

    if (expiryTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= expiryTime) {
        print('Token expired, clearing user data');
        await _clearUserData();
        return null;
      }
    }

    // Use SharedPreferences as PRIMARY storage for 24h session
    String? token = await _getTokenFromPrefs();

    if (token != null) {
      print('Token retrieved from SharedPreferences (primary storage)');
      return token;
    }

    // Fallback to SecureStorage if SharedPreferences fails
    try {
      token = await SecureStorage.getToken();
      if (token != null) {
        print('Token retrieved from SecureStorage (fallback)');
        // Save back to SharedPreferences for next time
        await _saveTokenToPrefs(token);
        return token;
      }
    } catch (e) {
      print('SecureStorage access failed: $e');
    }

    print('No token found in any storage');
    return null;
  }

  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final token = await getToken(); // This will check expiry automatically

      // Basic checks without API call for better performance
      if (!isLoggedIn) {
        print('Not logged in flag in SharedPreferences');
        return false;
      }

      if (token == null) {
        print('No token available');
        return false;
      }

      // Token exists and not expired, assume session is valid
      // Don't make API call unless specifically needed
      print('Session check successful (token available and not expired)');
      return true;
    } catch (e) {
      print('Error checking session: $e');
      // Don't clear data on errors, be more permissive
      return false;
    }
  }

  // Separate method for full token validation when needed
  Future<bool> validateCurrentSession() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'sukses') {
          print('Full session validation successful');
          return true;
        }
      }

      // Only clear data if it's definitely an auth issue
      if (response.statusCode == 401 || response.statusCode == 403) {
        print(
            'Session validation failed: ${response.statusCode} - ${response.body}');
        await _clearUserData();
        return false;
      }

      // For other errors, don't clear data
      print('Session validation failed (non-auth): ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  Future<bool> refreshSession() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'sukses' &&
            jsonData['data']['token'] != null) {
          final newToken = jsonData['data']['token'];

          // Save new token
          await SecureStorage.setToken(newToken);

          // Update session expiry
          final prefs = await SharedPreferences.getInstance();
          final newExpiryTime = DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch;
          await prefs.setInt('sessionExpiryTime', newExpiryTime);

          return true;
        }
      }

      await _clearUserData();
      return false;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'passwordConfirmation': passwordConfirmation,
        }),
      );

      final jsonData = jsonDecode(response.body);
      print('Register response: ${response.statusCode} - $jsonData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonData['status'] == 'sukses' && jsonData['data'] != null) {
          final data = jsonData['data'];
          final user = data['user'];
          final token = data['token'];

          if (token != null && user != null) {
            await _saveUserData(
              token: token,
              isAdmin: user['role'] == true || user['role'] == 1,
              userId: user['userID'] ?? user['id'] ?? 0,
              username: user['username'],
              email: user['email'],
              profilePicture: user['profilePicture'],
            );

            return {
              'success': true,
              'data': data,
              'message': jsonData['message'] ?? 'Registration successful',
            };
          }
        }
      }

      return {
        'success': false,
        'message': jsonData['message'] ?? 'Registration failed',
      };
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final jsonData = jsonDecode(response.body);
      print('Login response: ${response.statusCode} - $jsonData');

      if (response.statusCode == 200) {
        if (jsonData['status'] == 'sukses' && jsonData['data'] != null) {
          final data = jsonData['data'];
          final user = data['user'];
          final token = data['token'];

          if (token != null && user != null) {
            await _saveUserData(
              token: token,
              isAdmin: user['role'] == true || user['role'] == 1,
              userId: user['userID'] ?? user['id'] ?? 0,
              username: user['username'],
              email: user['email'],
              profilePicture: user['profilePicture'],
            );

            return {
              'success': true,
              'data': data,
              'message': jsonData['message'] ?? 'Login successful',
            };
          }
        }
      }

      return {
        'success': false,
        'message': jsonData['message'] ?? 'Login failed',
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();

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

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
    String? currentPassword,
    String? newPassword,
    File? profilePicture,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      if (username != null) request.fields['username'] = username;
      if (email != null) request.fields['email'] = email;
      if (currentPassword != null) {
        // Try different field names that backend might expect
        request.fields['currentPassword'] = currentPassword;
        request.fields['current_password'] =
            currentPassword; // snake_case alternative
        request.fields['password'] = currentPassword; // simple alternative
        print(
            '[AuthService] Current password provided: ${currentPassword.length} chars');
      }
      if (newPassword != null) {
        request.fields['newPassword'] = newPassword;
        request.fields['new_password'] = newPassword; // snake_case alternative
        print(
            '[AuthService] New password provided: ${newPassword.length} chars');
      }

      if (profilePicture != null) {
        final mimeType = lookupMimeType(profilePicture.path) ?? 'image/jpeg';
        final mimeParts = mimeType.split('/');

        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          profilePicture.path,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ));
      }

      print('[AuthService] updateProfile request fields: ${request.fields}');
      print(
          '[AuthService] updateProfile request files: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          '[AuthService] updateProfile response status: ${response.statusCode}');
      print('[AuthService] updateProfile response body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      print('[AuthService] updateProfile parsed response: $jsonData');

      if (response.statusCode == 200 && jsonData['status'] == 'sukses') {
        // Update stored user data if profile update was successful
        if (jsonData['data'] != null && jsonData['data']['user'] != null) {
          final user = jsonData['data']['user'];
          final prefs = await SharedPreferences.getInstance();

          if (user['username'] != null)
            await prefs.setString('username', user['username']);
          if (user['email'] != null)
            await prefs.setString('email', user['email']);
          if (user['profilePicture'] != null)
            await prefs.setString('profilePicture', user['profilePicture']);
        }

        return {
          'success': true,
          'data': jsonData['data'],
          'message': jsonData['message'] ?? 'Profile updated successfully',
        };
      }

      // Handle specific error cases
      String errorMessage = 'Failed to update profile';

      print('[AuthService] Error response - Status: ${response.statusCode}');
      print('[AuthService] Error response - Body: ${response.body}');
      print('[AuthService] Error response - Parsed: $jsonData');

      if (response.statusCode == 400 && jsonData['message'] != null) {
        final message = jsonData['message'].toString().toLowerCase();
        print('[AuthService] Processing 400 error message: $message');

        if (message.contains('password') &&
            (message.contains('wrong') ||
                message.contains('incorrect') ||
                message.contains('salah') ||
                message.contains('invalid'))) {
          errorMessage = 'Password saat ini salah';
        } else if (message.contains('email') && message.contains('exist')) {
          errorMessage = 'Email sudah digunakan';
        } else {
          errorMessage = jsonData['message'];
        }
      } else if (response.statusCode == 401) {
        errorMessage = 'Sesi telah berakhir, silakan login kembali';
      } else if (response.statusCode == 422 && jsonData['message'] != null) {
        // Handle validation errors
        final message = jsonData['message'].toString().toLowerCase();
        if (message.contains('password')) {
          errorMessage = 'Password saat ini salah';
        } else {
          errorMessage = jsonData['message'];
        }
      } else if (jsonData['message'] != null) {
        errorMessage = jsonData['message'];
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Update profile error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<void> debugTokenTest() async {
    print('=== DEBUG TOKEN TEST ===');
    final token = await getToken();
    print('Token available: ${token != null}');

    if (token != null) {
      print('Token length: ${token.length}');
      print('Token starts with: ${token.substring(0, 20)}...');

      // Test direct API call
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        print('Direct API test - Status: ${response.statusCode}');
        print('Direct API test - Body: ${response.body}');
      } catch (e) {
        print('Direct API test - Error: $e');
      }
    }
    print('=== END DEBUG TOKEN TEST ===');
  }

  // Alternative token storage using only SharedPreferences
  Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    print('Token saved to SharedPreferences');
  }

  Future<String?> _getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Token retrieved from SharedPreferences: ${token != null}');
    return token;
  }

  Future<void> _clearTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    print('Token cleared from SharedPreferences');
  }
}
