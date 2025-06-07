import 'dart:convert';
import 'dart:io';
import 'package:artefacto/model/artifact_model.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:geolocator/geolocator.dart';

class ArtifactService {
  static const baseUrl =
      "https://artefacto-backend-749281711221.us-central1.run.app/api/artifacts";

  // Request tracking untuk mencegah duplicate requests
  static final Set<String> _activeRequests = <String>{};

  // Mendapatkan header dengan token Authorization dan content-type JSON
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generate unique request key untuk tracking
  static String _generateRequestKey(
      String method, String endpoint, Map<String, dynamic>? data) {
    final dataString = data != null ? jsonEncode(data) : '';
    return '$method:$endpoint:$dataString';
  }

  // Ambil daftar artifacts
  static Future<List<Artifact>> getArtifacts() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final artifactsJson = jsonBody['data']['artifacts'] as List;
      return artifactsJson.map((json) => Artifact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load artifacts: ${response.statusCode}');
    }
  }

  // Ambil artifact berdasarkan id
  static Future<Artifact> getArtifactById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final artifactJson = jsonBody['data']['artifact'];
      return Artifact.fromJson(artifactJson);
    } else {
      throw Exception('Failed to get artifact: ${response.statusCode}');
    }
  }

  // Membuat artifact baru dengan upload gambar (multipart) - with deduplication
  static Future<Artifact> createArtifactWithImage({
    required Artifact artifact,
    File? imageFile,
  }) async {
    final requestData = {
      'templeID': artifact.templeID,
      'title': artifact.title,
      'description': artifact.description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final requestKey = _generateRequestKey('POST', baseUrl, requestData);

    // Tambahkan pengecekan lebih ketat
    if (_activeRequests.contains(requestKey)) {
      throw Exception('Duplicate request prevented');
    }

    _activeRequests.add(requestKey);
    print('Request started: $requestKey'); // Debug logging

    try {
      final token = await AuthService().getToken();
      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields dengan null checking
      request.fields['templeID'] = artifact.templeID.toString();
      request.fields['title'] = artifact.title.trim();
      request.fields['description'] = artifact.description.trim();

      if (artifact.detailPeriod != null &&
          artifact.detailPeriod!.trim().isNotEmpty) {
        request.fields['detailPeriod'] = artifact.detailPeriod!.trim();
      }
      if (artifact.detailMaterial != null &&
          artifact.detailMaterial!.trim().isNotEmpty) {
        request.fields['detailMaterial'] = artifact.detailMaterial!.trim();
      }
      if (artifact.detailSize != null &&
          artifact.detailSize!.trim().isNotEmpty) {
        request.fields['detailSize'] = artifact.detailSize!.trim();
      }
      if (artifact.detailStyle != null &&
          artifact.detailStyle!.trim().isNotEmpty) {
        request.fields['detailStyle'] = artifact.detailStyle!.trim();
      }
      if (artifact.funfactTitle != null &&
          artifact.funfactTitle!.trim().isNotEmpty) {
        request.fields['funfactTitle'] = artifact.funfactTitle!.trim();
      }
      if (artifact.funfactDescription != null &&
          artifact.funfactDescription!.trim().isNotEmpty) {
        request.fields['funfactDescription'] =
            artifact.funfactDescription!.trim();
      }
      if (artifact.locationUrl != null &&
          artifact.locationUrl!.trim().isNotEmpty) {
        request.fields['locationUrl'] = artifact.locationUrl!.trim();
      }

      if (imageFile != null && await imageFile.exists()) {
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final json = jsonDecode(responseBody);
        final artifactJson = json['data']['artifact'];
        return Artifact.fromJson(artifactJson);
      } else {
        throw Exception(
          'Failed to create artifact: ${response.statusCode} - $responseBody',
        );
      }
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  // Update artifact dengan image (upload multipart) - with deduplication
  static Future<Artifact> updateArtifactWithImage(
    Artifact artifact,
    File? imageFile,
  ) async {
    // Generate unique request key
    final requestData = {
      'artifactID': artifact.artifactID,
      'templeID': artifact.templeID,
      'title': artifact.title,
      'description': artifact.description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final requestKey = _generateRequestKey(
        'PUT', "$baseUrl/${artifact.artifactID}", requestData);

    // Check if request is already in progress
    if (_activeRequests.contains(requestKey)) {
      throw Exception('Update request already in progress');
    }

    _activeRequests.add(requestKey);

    try {
      final token = await AuthService().getToken();
      final uri = Uri.parse("$baseUrl/${artifact.artifactID}");
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields dengan null checking
      request.fields['templeID'] = artifact.templeID.toString();
      request.fields['title'] = artifact.title.trim();
      request.fields['description'] = artifact.description.trim();

      if (artifact.detailPeriod != null &&
          artifact.detailPeriod!.trim().isNotEmpty) {
        request.fields['detailPeriod'] = artifact.detailPeriod!.trim();
      }
      if (artifact.detailMaterial != null &&
          artifact.detailMaterial!.trim().isNotEmpty) {
        request.fields['detailMaterial'] = artifact.detailMaterial!.trim();
      }
      if (artifact.detailSize != null &&
          artifact.detailSize!.trim().isNotEmpty) {
        request.fields['detailSize'] = artifact.detailSize!.trim();
      }
      if (artifact.detailStyle != null &&
          artifact.detailStyle!.trim().isNotEmpty) {
        request.fields['detailStyle'] = artifact.detailStyle!.trim();
      }
      if (artifact.funfactTitle != null &&
          artifact.funfactTitle!.trim().isNotEmpty) {
        request.fields['funfactTitle'] = artifact.funfactTitle!.trim();
      }
      if (artifact.funfactDescription != null &&
          artifact.funfactDescription!.trim().isNotEmpty) {
        request.fields['funfactDescription'] =
            artifact.funfactDescription!.trim();
      }
      if (artifact.locationUrl != null &&
          artifact.locationUrl!.trim().isNotEmpty) {
        request.fields['locationUrl'] = artifact.locationUrl!.trim();
      }

      if (imageFile != null && await imageFile.exists()) {
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final artifactJson = json['data']['artifact'];
        return Artifact.fromJson(artifactJson);
      } else {
        throw Exception(
          'Failed to update artifact: ${response.statusCode} - $responseBody',
        );
      }
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  // Update artifact tanpa image (pakai JSON biasa)
  static Future<Artifact> updateArtifactWithoutImage(Artifact artifact) async {
    final headers = await _getHeaders();
    final uri = Uri.parse("$baseUrl/${artifact.artifactID}");

    final body = {
      'templeID': artifact.templeID,
      'title': artifact.title.trim(),
      'description': artifact.description.trim(),
      if (artifact.detailPeriod != null &&
          artifact.detailPeriod!.trim().isNotEmpty)
        'detailPeriod': artifact.detailPeriod!.trim(),
      if (artifact.detailMaterial != null &&
          artifact.detailMaterial!.trim().isNotEmpty)
        'detailMaterial': artifact.detailMaterial!.trim(),
      if (artifact.detailSize != null && artifact.detailSize!.trim().isNotEmpty)
        'detailSize': artifact.detailSize!.trim(),
      if (artifact.detailStyle != null &&
          artifact.detailStyle!.trim().isNotEmpty)
        'detailStyle': artifact.detailStyle!.trim(),
      if (artifact.funfactTitle != null &&
          artifact.funfactTitle!.trim().isNotEmpty)
        'funfactTitle': artifact.funfactTitle!.trim(),
      if (artifact.funfactDescription != null &&
          artifact.funfactDescription!.trim().isNotEmpty)
        'funfactDescription': artifact.funfactDescription!.trim(),
      if (artifact.locationUrl != null &&
          artifact.locationUrl!.trim().isNotEmpty)
        'locationUrl': artifact.locationUrl!.trim(),
    };

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final artifactJson = jsonBody['data']['artifact'];
      return Artifact.fromJson(artifactJson);
    } else {
      throw Exception(
        'Failed to update artifact without image: ${response.statusCode}',
      );
    }
  }

  // Hapus artifact
  static Future<void> deleteArtifact(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete artifact: ${response.statusCode}');
    }
  }

  // Clear active requests (untuk debugging)
  static void clearActiveRequests() {
    _activeRequests.clear();
  }

  static Future<List<Artifact>> getNearbyArtifacts(
    double latitude,
    double longitude, {
    double radiusInKm = 5.0,
  }) async {
    final allArtifacts = await getArtifacts();
    final List<Map<String, dynamic>> artifactsWithDistance = [];

    for (final artifact in allArtifacts) {
      if (artifact.latitude != null && artifact.longitude != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          latitude,
          longitude,
          artifact.latitude!,
          artifact.longitude!,
        );

        final double distanceInKm = distanceInMeters / 1000;

        if (distanceInKm <= radiusInKm) {
          artifactsWithDistance.add({
            'artifact': artifact,
            'distance': distanceInKm,
          });
        }
      }
    }

    // Urutkan berdasarkan jarak
    artifactsWithDistance.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Kembalikan hanya objek artefak
    return artifactsWithDistance.map((e) => e['artifact'] as Artifact).toList();
  }

  // Fungsi baru untuk menandai artefak sebagai telah dibaca
  static Future<void> markArtifactAsRead(int artifactId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse("$baseUrl/$artifactId/read");

    try {
      final response = await http.post(uri, headers: headers);
      if (response.statusCode != 200) {
        // Log error atau handle, tapi jangan sampai crash
        print('Failed to mark artifact as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking artifact as read: $e');
    }
  }

  // Fungsi untuk menambah bookmark
  static Future<void> bookmarkArtifact(int artifactId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse("$baseUrl/$artifactId/bookmark");
    try {
      final response = await http.post(uri, headers: headers);
      if (response.statusCode != 200) {
        print('Failed to bookmark artifact: ${response.statusCode}');
      }
    } catch (e) {
      print('Error bookmarking artifact: $e');
    }
  }

  // Fungsi untuk menghapus bookmark
  static Future<void> unbookmarkArtifact(int artifactId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse("$baseUrl/$artifactId/bookmark");
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode != 200) {
        print('Failed to unbookmark artifact: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unbookmarking artifact: $e');
    }
  }
}
