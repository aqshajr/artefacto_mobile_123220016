import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/owned_ticket_model.dart';
import '../model/tiket_model.dart';
import '../service/auth_service.dart';

class TicketService {
  static const String baseUrl =
      'https://artefacto-backend-749281711221.us-central1.run.app/api';

  static Future<List<OwnedTicket>> getMyTickets() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/owned-tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'sukses' && data['data'] != null) {
          final List<dynamic> ticketsJson = data['data']['ownedTickets'];
          return ticketsJson.map((json) => OwnedTicket.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to get owned tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get owned tickets: $e');
    }
  }

  static Future<void> useTicket(int ticketId) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/owned-tickets/$ticketId/use'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to use ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to use ticket: $e');
    }
  }

  // New methods for admin ticket management
  static Future<TicketResponse> getTickets() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return TicketResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return TicketResponse(
        status: 'error',
        message: 'Failed to get tickets: $e',
      );
    }
  }

  static Future<TicketResponse> createTicket(TicketRequest request) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      return TicketResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return TicketResponse(
        status: 'error',
        message: 'Failed to create ticket: $e',
      );
    }
  }

  static Future<TicketResponse> updateTicket(
      int ticketId, TicketRequest request) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/tickets/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      return TicketResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return TicketResponse(
        status: 'error',
        message: 'Failed to update ticket: $e',
      );
    }
  }

  static Future<TicketResponse> deleteTicket(int ticketId) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/tickets/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return TicketResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return TicketResponse(
        status: 'error',
        message: 'Failed to delete ticket: $e',
      );
    }
  }
}
