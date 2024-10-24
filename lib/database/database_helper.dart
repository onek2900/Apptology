import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/printer_model.dart'; // Import your PrinterModel class

class DatabaseHelper {
  static final _databaseName = "PrinterDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'printer_table';
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();  // Initialize database if it's null or closed
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory? appDir = await getExternalStorageDirectory(); // Get external storage directory
    String path = join(appDir!.path, _databaseName); // Custom path for the database file
    print("Database path: $path"); // Debugging, print the path where the DB is saved
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      printerId TEXT NOT NULL,
      isMain INTEGER NOT NULL
    )
  ''');
  }

  // Insert printer into the database
  Future<int> insertPrinter(PrinterModel printer) async {
    Database db = await instance.database;
    return await db.insert(table, printer.toMap());
  }

  // Update printer information in the database
  Future<int> updatePrinter(PrinterModel printer) async {
    Database db = await instance.database;
    return await db.update(
      table,
      printer.toMap(),
      where: 'id = ?',
      whereArgs: [printer.id],
    );
  }

  // Fetch all printers from the database
  Future<List<PrinterModel>> getAllPrinters() async {
    Database db = await instance.database;
    var printers = await db.query(table, orderBy: 'id');
    List<PrinterModel> printerList = printers.isNotEmpty
        ? printers.map((c) => PrinterModel.fromMap(c)).toList()
        : [];
    return printerList;
  }

  // Fetch printer by category from the database
  Future<PrinterModel?> getPrinterByCategory(String categoryId) async {
    Database db = await instance.database;
    var res = await db.query(
      table,
      where: 'category = ?',
      whereArgs: [categoryId],
    );
    if (res.isNotEmpty) {
      return PrinterModel.fromMap(res.first);
    }
    return null; // Return null if no printer with the category is found
  }


  // Delete all printers from the database
  Future<void> deleteAllPrinters() async {
    Database db = await instance.database;
    await db.delete(table); // Deletes all records from the printer table
    print("All printers deleted from the database");
  }


// Other CRUD operations...
}
