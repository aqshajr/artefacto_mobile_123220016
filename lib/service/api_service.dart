import 'dart:convert';
import 'package:http/http.dart' as http;
import '../service/auth_service.dart';

class ApiService {
  final String baseUrl =
      'https://artefacto-backend-749281711221.us-central1.run.app/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    print(
        'ApiService - Getting token: ${token != null ? 'Found' : 'NOT FOUND'}');
    if (token != null) {
      print('ApiService - Token length: ${token.length}');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(
      http.Response response, String endpoint) async {
    final jsonData = jsonDecode(response.body);

    // Handle successful response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': jsonData,
        'statusCode': response.statusCode,
      };
    }

    // Handle authentication errors
    if (response.statusCode == 401) {
      print('Authentication failed for $endpoint: ${response.body}');

      // DISABLE automatic logout to prevent premature session clearing
      // Check if it's an expired token issue
      // if (jsonData['message']?.toString().toLowerCase().contains('expired') == true ||
      //     jsonData['message']?.toString().toLowerCase().contains('invalid') == true ||
      //     jsonData['message']?.toString().toLowerCase().contains('unauthorized') == true) {
      //   // Clear user data and return session expired error
      //   await _authService.logout();
      //   throw Exception('Session expired, please login again');
      // }

      // For all 401 errors, just return error without logout
      return {
        'success': false,
        'message': jsonData['message'] ?? 'Authentication failed',
        'statusCode': response.statusCode,
        'data': jsonData,
      };
    }

    // Handle other errors
    String errorMessage = 'Request failed';
    if (jsonData['message'] != null) {
      errorMessage = jsonData['message'];
    } else if (jsonData['error'] != null) {
      errorMessage = jsonData['error'];
    }

    return {
      'success': false,
      'message': errorMessage,
      'statusCode': response.statusCode,
      'data': jsonData,
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      print('GET request to: $baseUrl$endpoint');
      print('Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return await _handleResponse(response, endpoint);
    } catch (e) {
      print('GET request error for $endpoint: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      print('POST request to: $baseUrl$endpoint');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return await _handleResponse(response, endpoint);
    } catch (e) {
      print('POST request error for $endpoint: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      print('PUT request to: $baseUrl$endpoint');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return await _handleResponse(response, endpoint);
    } catch (e) {
      print('PUT request error for $endpoint: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      print('DELETE request to: $baseUrl$endpoint');
      print('Headers: $headers');

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return await _handleResponse(response, endpoint);
    } catch (e) {
      print('DELETE request error for $endpoint: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  // Specific API endpoints
  Future<Map<String, dynamic>> getStatistics() async {
    return await get('/statistics');
  }

  Future<Map<String, dynamic>> getTemples() async {
    return await get('/temples');
  }

  Future<Map<String, dynamic>> getTickets() async {
    return await get('/tickets');
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    return await put('/auth/profile', userData);
  }

  // User profile endpoint
  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/auth/profile');
  }

  // Artifacts endpoints
  Future<Map<String, dynamic>> getArtifacts() async {
    return await get('/artifacts');
  }

  Future<Map<String, dynamic>> getArtifactById(int id) async {
    return await get('/artifacts/$id');
  }

  // Temple details endpoint
  Future<Map<String, dynamic>> getTempleById(int id) async {
    return await get('/temples/$id');
  }
}
