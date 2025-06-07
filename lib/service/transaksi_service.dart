import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:artefacto/model/transaction_model.dart';
import 'auth_service.dart';

class TransaksiService {
  static const baseUrl = "https://artefacto-backend-749281711221.us-central1.run.app";
  static const transactionEndpoint = "/api/transactions";
  static const timeoutDuration = Duration(seconds: 60);

  // Get headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing or invalid');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all transactions
  static Future<TransactionListResponse> getTransactions() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$transactionEndpoint');

      print('GET Request to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers)
          .timeout(timeoutDuration);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return TransactionListResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTransactions: $e');
      rethrow;
    }
  }

  // Create new transaction
  static Future<TransactionResponse> createTransaction(
      TransactionRequest transactionRequest) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$transactionEndpoint');
      final body = jsonEncode(transactionRequest.toJson());

      print('POST Request to: $uri');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(uri, headers: headers, body: body)
          .timeout(timeoutDuration);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return TransactionResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createTransaction: $e');
      rethrow;
    }
  }
}