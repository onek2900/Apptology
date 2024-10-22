import 'dart:async';
import 'package:path/path.dart';
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
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    var resultint = await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
    _isTableExists;
    return resultint;
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

  // Fetch all printers from the database
  Future<List<PrinterModel>> getAllPrinters() async {
    Database db = await instance.database;
    var printers = await db.query(table, orderBy: 'id');
    List<PrinterModel> printerList = printers.isNotEmpty
        ? printers.map((c) => PrinterModel.fromMap(c)).toList()
        : [];
    return printerList;
  }
  Future<bool> _isTableExists(Database db, String tableName) async {
    Database db = await instance.database;
    var res = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
    print(res);
    return res.isNotEmpty;
  }
  // Delete all printers from the database
  Future<void> deleteAllPrinters() async {
    Database db = await instance.database;
    bool tableExists = await _isTableExists(db, table); // Check if the table exists
    if (tableExists) {
      await db.delete(table); // Delete all printers if the table exists
    } else {
      await _initDatabase(); // If the table doesn't exist, initialize the database
    }
  }

  Future<PrinterModel?> getMainPrinter() async {
    Database db = await instance.database;
    var res = await db.query(table, where: 'isMain = ?', whereArgs: [1]);
    if (res.isNotEmpty) {
      return PrinterModel.fromMap(res.first);
    }
    return null;
  }

  Future<PrinterModel?> getSecPrinter() async {
    Database db = await instance.database;
    // Assuming secondary printers have 'isMain = 0'
    var res = await db.query(table, where: 'isMain = ?', whereArgs: [0]);

    if (res.isNotEmpty) {
      return PrinterModel.fromMap(res.first);
    }
    return null; // Return null if no secondary printer is found
  }


  // Set printer as the main printer
  Future<void> setAsMainPrinter(int id) async {
    Database db = await instance.database;
    await db.update(table, {'isMain': 0}, where: 'isMain = 1'); // Clear previous main
    await db.update(table, {'isMain': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Clear main printer status
  Future<void> clearMainPrinter() async {
    Database db = await instance.database;
    await db.update(table, {'isMain': 0});
  }

  // Method to unset the current main printer
  Future<void> unsetMainPrinter() async {
    Database db = await instance.database;
    await db.update(
      table,
      {'isMain': 0}, // Set isMain to 0 for all printers
    );
  }

  Future<void> setMainPrinter(String printerId) async {
    Database db = await instance.database;
    await unsetMainPrinter(); // First unset all printers

    // Set the selected printer as the main one
    await db.update(
      table,
      {'isMain': 1},
      where: 'printerId = ?',
      whereArgs: [printerId],
    );
  }

// Function to delete the database
  Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path); // Correctly pass the path argument here
  }

}
