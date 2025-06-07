import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:artefacto/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:artefacto/utils/constants.dart';
import 'package:artefacto/utils/secure_storage.dart';

class UserService {
  static const baseUrl = "${Constants.baseUrl}/auth";

  Future<User?> getCurrentUser() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'sukses' && data['data'] != null) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String email,
  }) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateProfilePicture(File imageFile) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/auth/update-profile-picture'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              jsonResponse['message'] ?? 'Failed to update profile picture',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
