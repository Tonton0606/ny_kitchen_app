import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final categoriesToRemove = [
    'Rice meals', 'snacks', 'pasta', 'beverages', 'desserts', 'speicals',
    'float', 'soup', 'drinks', 'Meow', 'lalala', 'specials', 'Rice Meals', 'Snacks'
  ];

  // Retrieve Supabase credentials dynamically from environment or local .env
  String supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  String anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  // Fallback: read from local .env if present and environment variables not set
  final envFile = File('.env');
  if ((supabaseUrl.isEmpty || anonKey.isEmpty) && envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
      final idx = trimmed.indexOf('=');
      final key = trimmed.substring(0, idx).trim();
      final val = trimmed.substring(idx + 1).trim();
      if (key == 'SUPABASE_URL' && supabaseUrl.isEmpty) supabaseUrl = val;
      if (key == 'SUPABASE_ANON_KEY' && anonKey.isEmpty) anonKey = val;
    }
  }

  if (supabaseUrl.isEmpty || anonKey.isEmpty) {
    print('ERROR: SUPABASE_URL or SUPABASE_ANON_KEY not configured.');
    print('Please set them in your environment or in a local .env file.');
    exit(1);
  }

  final inList = categoriesToRemove.map((c) => '"$c"').join(',');
  final url = Uri.parse('$supabaseUrl/rest/v1/food_categories?name=in.($inList)');

  try {
    final response = await http.patch(
      url,
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: '{"status": "archived"}'
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Successfully archived categories in Supabase cloud!');
    } else {
      print('Failed to archive in Supabase: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error contacting Supabase: $e');
  }

  exit(0);
}
