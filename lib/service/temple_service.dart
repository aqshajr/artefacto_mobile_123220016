import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:artefacto/model/temple_model.dart';
import 'auth_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:geolocator/geolocator.dart';

class TempleService {
  static const String baseUrl =
      "https://artefacto-backend-749281711221.us-central1.run.app/api/temples";

  // Mendapatkan headers dengan token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Ambil semua temple (list)
  static Future<List<Temple>> getTemples() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final templeModel = TempleModel.fromJson(jsonResponse);
      return templeModel.data?.temples ?? [];
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else {
      throw Exception('Failed to load temples: ${response.statusCode}');
    }
  }

  // Ambil temple berdasarkan ID
  static Future<Temple> getTempleById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final templeJson = jsonResponse['data']['temple'] ?? jsonResponse['data'];
      return Temple.fromJson(templeJson);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else {
      throw Exception('Failed to get temple: ${response.statusCode}');
    }
  }

  // Tambah candi baru dengan optional image
  static Future<Temple> createTempleWithImage({
    required String title,
    required String description,
    String? funfactTitle,
    String? funfactDescription,
    String? locationUrl,
    File? imageFile,
  }) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    if (funfactTitle != null && funfactTitle.isNotEmpty)
      request.fields['funfactTitle'] = funfactTitle;
    if (funfactDescription != null && funfactDescription.isNotEmpty)
      request.fields['funfactDescription'] = funfactDescription;
    if (locationUrl != null && locationUrl.isNotEmpty)
      request.fields['locationUrl'] = locationUrl;

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      imageFile.path.split('.').last.toLowerCase();
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
      final templeJson = json['data']['temple'];
      return Temple.fromJson(templeJson);
    } else {
      throw Exception(
        'Failed to create temple: ${response.statusCode} - $responseBody',
      );
    }
  }

  // Edit temple tanpa ubah foto
  static Future<Temple> updateTempleWithoutImage({
    required int templeId,
    required String title,
    required String description,
    String? funfactTitle,
    String? funfactDescription,
    String? locationUrl,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse("$baseUrl/$templeId");

    final body = {
      'title': title,
      'description': description,
      if (funfactTitle != null) 'funfactTitle': funfactTitle,
      if (funfactDescription != null) 'funfactDescription': funfactDescription,
      if (locationUrl != null) 'locationUrl': locationUrl,
    };

    final response = await http.put(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final templeJson = json['data']['temple'];
      return Temple.fromJson(templeJson);
    } else {
      throw Exception('Failed to update temple: ${response.statusCode}');
    }
  }

  // Edit temple dengan image
  static Future<Temple> updateTempleWithImage({
    required int templeId,
    required String title,
    required String description,
    String? funfactTitle,
    String? funfactDescription,
    String? locationUrl,
    File? imageFile,
  }) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse("$baseUrl/$templeId");
    final request = http.MultipartRequest('PUT', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    if (funfactTitle != null && funfactTitle.isNotEmpty)
      request.fields['funfactTitle'] = funfactTitle;
    if (funfactDescription != null && funfactDescription.isNotEmpty)
      request.fields['funfactDescription'] = funfactDescription;
    if (locationUrl != null && locationUrl.isNotEmpty)
      request.fields['locationUrl'] = locationUrl;

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      imageFile.path.split('.').last.toLowerCase();
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
      final templeJson = json['data']['temple'];
      return Temple.fromJson(templeJson);
    } else {
      throw Exception(
        'Failed to update temple with image: ${response.statusCode} - $responseBody',
      );
    }
  }

  // Hapus temple
  static Future<void> deleteTemple(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete temple: ${response.statusCode}');
    }
  }

  static Future<List<Temple>> getNearbyTemples({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) async {
    print('[TempleService] getNearbyTemples called');
    print('[TempleService] User location: $latitude, $longitude');
    print('[TempleService] Search radius: ${radiusInKm}km');

    final allTemples = await getTemples();
    print('[TempleService] Total temples fetched: ${allTemples.length}');

    final List<Map<String, dynamic>> templesWithDistance = [];

    for (final temple in allTemples) {
      print('[TempleService] Processing temple: ${temple.title}');
      print(
          '[TempleService] Temple coordinates: ${temple.latitude}, ${temple.longitude}');
      print('[TempleService] Temple locationUrl: ${temple.locationUrl}');

      // Try to parse coordinates from URL if lat/lng are null
      double? lat = temple.latitude;
      double? lng = temple.longitude;

      if ((lat == null || lng == null) && temple.locationUrl != null) {
        print('[TempleService] Trying to parse coordinates from URL...');
        final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
        final match = regex.firstMatch(temple.locationUrl!);
        if (match != null) {
          lat = double.tryParse(match.group(1)!);
          lng = double.tryParse(match.group(2)!);
          print('[TempleService] Parsed coordinates from URL: $lat, $lng');
        }
      }

      if (lat != null && lng != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          latitude,
          longitude,
          lat,
          lng,
        );

        final double distanceInKm = distanceInMeters / 1000;
        print(
            '[TempleService] Distance to ${temple.title}: ${distanceInKm.toStringAsFixed(2)}km');

        if (distanceInKm <= radiusInKm) {
          templesWithDistance.add({
            'temple': temple,
            'distance': distanceInKm,
          });
          print('[TempleService] Temple ${temple.title} added to nearby list');
        } else {
          print(
              '[TempleService] Temple ${temple.title} too far (${distanceInKm.toStringAsFixed(2)}km > ${radiusInKm}km)');
        }
      } else {
        print('[TempleService] Temple ${temple.title} has no coordinates');
      }
    }

    // Sort by distance
    templesWithDistance.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    final nearbyTemples =
        templesWithDistance.map((e) => e['temple'] as Temple).toList();
    print('[TempleService] Returning ${nearbyTemples.length} nearby temples');

    // Return only the temple objects
    return nearbyTemples;
  }
}
