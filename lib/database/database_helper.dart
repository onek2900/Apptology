import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/printer_model.dart'; // Import your PrinterModel class

class DatabaseHelper {
  static final _databaseName = "PrinterDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'printers';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Reference to the database
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT
      )
    ''');
  }

  // Insert a printer into the database
  Future<int> insertPrinter(PrinterModel printer) async {
    Database db = await instance.database;
    return await db.insert(table, printer.toMap());
  }

  // Get all printers from the database
  Future<List<PrinterModel>> getPrinters() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);

    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) {
        return PrinterModel.fromMap(maps[i]);
      });
    } else {
      return [];
    }
  }

  // Delete all printers from the database
  Future<int> deleteAllPrinters() async {
    Database db = await instance.database;
    return await db.delete(table);
  }
}
