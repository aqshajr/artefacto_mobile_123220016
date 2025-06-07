import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:artefacto/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UserApi {
  static const baseUrl = "https://artefacto-backend-749281711221.us-central1.run.app/api/auth";

  // Helper method untuk mendapatkan headers dengan token
  static Future<Map<String, String>> _getHeaders({
    bool jsonContentType = true,
    bool multipart = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final headers = <String, String>{};

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (jsonContentType && !multipart) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  static Future<UserModel> deleteUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/profile"), // Hapus parameter ID
        headers: headers,
      );

      final responseBody = jsonDecode(response.body);

      // Gunakan UserModel untuk parsing response
      final userModel = UserModel.fromJson(responseBody);

      if (response.statusCode == 200) {
        return userModel;
      } else {
        throw Exception(userModel.message ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Exception occurred: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/profile/$id"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user by id: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateUserWithImage(
      User user, File? imageFile) async {
    try {
      final headers = await _getHeaders(jsonContentType: false, multipart: true);
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      if (user.username != null) {
        request.fields['username'] = user.username!;
      }
      if (user.email != null) {
        request.fields['email'] = user.email!;
      }
      if (user.currentPassword != null) {
        request.fields['currentPassword'] = user.currentPassword!;
      }
      if (user.newPassword != null) {
        request.fields['newPassword'] = user.newPassword!;
      }
      if (user.confirmNewPassword != null) {
        request.fields['confirmNewPassword'] = user.confirmNewPassword!;
      }

      // Add image file if exists
      if (imageFile != null && await imageFile.exists()) {
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        final allowedTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
        ];

        if (!allowedTypes.contains(mimeType)) {
          return {
            'success': false,
            'message': 'File harus berupa gambar (JPG, PNG, GIF)',
          };
        }

        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          return {'success': false, 'message': 'Ukuran file maksimal 5MB'};
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        final contentType = streamedResponse.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final json = jsonDecode(responseBody);
          return {
            'success': true,
            'data': json,
          };
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format',
            'raw': responseBody,
          };
        }
      } else {
        // Response error
        return {
          'success': false,
          'message': 'Failed to update user. Status code: ${streamedResponse.statusCode}',
          'raw': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred: $e',
      };
    }
  }
}