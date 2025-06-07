import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ModelService {
  final String baseUrl =
      'https://artefacto-749281711221.asia-southeast2.run.app';

  Future<Map<String, dynamic>> predictArtifact(File image) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(respStr);
        return {
          'prediction': jsonResponse['prediction'] ?? 'Tidak dapat memprediksi',
          'confidence': jsonResponse['confidence'] ?? 0.0,
        };
      } else {
        throw _handleError(response.statusCode, respStr);
      }
    } catch (e) {
      throw _formatException(e);
    }
  }

  String _handleError(int statusCode, String response) {
    switch (statusCode) {
      case 400:
        return 'Request tidak valid: $response';
      case 500:
        return 'Server error: $response';
      default:
        return 'Error $statusCode: $response';
    }
  }

  String _formatException(dynamic e) {
    if (e is SocketException) {
      return 'Tidak ada koneksi internet';
    } else if (e is http.ClientException) {
      return 'Gagal terhubung ke server';
    } else {
      return 'Terjadi kesalahan: ${e.toString()}';
    }
  }
}
