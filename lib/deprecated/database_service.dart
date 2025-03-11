import 'dart:ui'; // ✅ Import Flutter color handling
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/pattern_model.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'kente_codeweaver.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            experiencePoints INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            colors TEXT,
            difficultyLevel INTEGER
          )
        ''');
      },
    );
  }

  Future<void> savePattern(KentePattern pattern) async {
    final db = await database;
    await db.insert(
      'patterns',
      {
        'name': pattern.name,
        'colors': jsonEncode(pattern.colors.map((c) => c.value.toRadixString(16)).toList()),
        'difficultyLevel': pattern.difficultyLevel,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<KentePattern>> loadPatterns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('patterns');

    return List.generate(maps.length, (i) {
      return KentePattern(
        name: maps[i]['name'],
        colors: (jsonDecode(maps[i]['colors']) as List)
            .map((c) => Color(int.parse(c.toString(), radix: 16)))
            .toList(),
        patternGrid: [],
        difficultyLevel: maps[i]['difficultyLevel'],
      );
    });
  }
}
