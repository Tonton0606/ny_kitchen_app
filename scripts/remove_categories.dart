import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = r'C:\Users\User\OneDrive\Documents\ny_kitchen.db';
  var db = await databaseFactory.openDatabase(dbPath);

  final categoriesToRemove = [
    'Rice meals', 'snacks', 'pasta', 'beverages', 'desserts', 'speicals',
    'float', 'soup', 'drinks', 'Meow', 'lalala'
  ];

  for (var name in categoriesToRemove) {
    await db.rawUpdate(
      '''
      UPDATE food_categories
      SET status = 'archived'
      WHERE name COLLATE NOCASE = ?
      ''',
      [name]
    );
  }

  print('Archived categories.');
  
  final result = await db.rawQuery("SELECT id, name, status FROM food_categories WHERE status = 'active'");
  print('Remaining active categories:');
  for (var row in result) {
    print(row);
  }
  
  await db.close();
  exit(0);
}
