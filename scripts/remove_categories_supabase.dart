import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final categoriesToRemove = [
    'Rice meals', 'snacks', 'pasta', 'beverages', 'desserts', 'speicals',
    'float', 'soup', 'drinks', 'Meow', 'lalala', 'specials', 'Rice Meals', 'Snacks'
  ];

  // Update Supabase via REST API
  final String supabaseUrl = 'https://wiuttklnxkagrvydekvt.supabase.co';
  final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndpdXR0a2xueGthZ3J2eWRla3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1MDIzMzksImV4cCI6MjEwMDA3ODMzOX0.74wRSujtW-8DfMOVJVfI3LMnLtj1DFH2AtzMQzq88UE';

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
