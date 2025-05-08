import 'dart:developer';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'user_modal.dart';
import 'dart:async';
import 'dart:io';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Getter to retrieve the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'user_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the user table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      phone TEXT UNIQUE,
      email TEXT UNIQUE,
      password TEXT,
      profileImagePath TEXT
    )
  ''');
    log("Users table created");
  }


  // Insert a new user (Register)
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Retrieve user by phone (for Login or Forgot Password)
  Future<UserModel?> getUserByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null; // No user found
  }

  // Update user password
  Future<int> updatePassword(String phone, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  // Get the last logged-in user (basic version — assumes only one user is stored)
  Future<UserModel?> getLastLoggedInUser() async {
    final db = await database;
    final result = await db.query('users', limit: 1);

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

}
