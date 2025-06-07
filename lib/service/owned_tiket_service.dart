import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:artefacto/model/owned_tiket_model.dart';
import 'auth_service.dart';

class OwnedTicketService {
  static const baseUrl = "https://artefacto-backend-749281711221.us-central1.run.app/api/owned-tickets";

  // Mendapatkan headers dengan token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all owned tickets for a user
  static Future<OwnedTicketResponse> getOwnedTickets() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      return OwnedTicketResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tickets: ${response.statusCode}');
    }
  }

  // Get single owned ticket by ID
  static Future<OwnedTicketByIdResponse> getOwnedTicketById(int ownedTicketId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/$ownedTicketId"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return OwnedTicketByIdResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load ticket: ${response.statusCode}');
    }
  }
}