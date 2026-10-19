import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class AIServiceClient {
  static const String _baseUrl = 'http://127.0.0.1:5000';
  final String? _explicitServiceKey;

  AIServiceClient({String? serviceKey}) : _explicitServiceKey = serviceKey;

  /// Returns the configured service key from explicit parameter or dotenv (never hardcoded).
  String? get serviceKey {
    if (_explicitServiceKey != null) {
      return _explicitServiceKey.isNotEmpty ? _explicitServiceKey : null;
    }
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.maybeGet('AI_SERVICE_KEY') ?? dotenv.env['AI_SERVICE_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return null;
  }

  /// Headers to include with requests, including the X-Service-Key authentication header.
  Map<String, String> get headers {
    final key = serviceKey;
    if (key != null && key.isNotEmpty) {
      return {'X-Service-Key': key};
    }
    return {};
  }

  /// Sends an image file to the Python API to extract the 128D face encoding.
  Future<List<double>?> extractEncoding(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/extract_encoding'));
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['encoding'] != null) {
          final List<dynamic> rawList = data['encoding'];
          return rawList.map((e) => (e as num).toDouble()).toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing AI service key');
      } else {
        throw Exception(jsonDecode(responseBody)['detail'] ?? 'Failed to extract face');
      }
    } catch (e) {
      throw Exception('Face extraction error: $e');
    }
    return null;
  }

  /// Sends an image file to check if the user's eyes are closed (liveness detection).
  Future<bool?> checkEyesClosed(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/check_liveness'));
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['error'] != null) {
          return null; // Face not found or eyes not detected
        }
        return data['eyes_closed'] as bool?;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or missing AI service key');
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        rethrow;
      }
      // Ignore non-auth errors for liveness checks so we don't spam the UI
    }
    return null;
  }


  /// Calculates the Euclidean distance between two face encodings.
  /// A distance less than 0.5 typically indicates a match.
  double calculateEuclideanDistance(List<double> encoding1, List<double> encoding2) {
    if (encoding1.length != encoding2.length) {
      throw Exception('Encodings must have the same length');
    }
    double sum = 0.0;
    for (int i = 0; i < encoding1.length; i++) {
      double diff = encoding1[i] - encoding2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}
