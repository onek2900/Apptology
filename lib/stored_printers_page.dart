import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/printer_model.dart';

class StoredPrintersPage extends StatefulWidget {
  @override
  _StoredPrintersPageState createState() => _StoredPrintersPageState();
}

class _StoredPrintersPageState extends State<StoredPrintersPage> {
  List<PrinterModel> printers = [];

  @override
  void initState() {
    super.initState();
    _getStoredPrinters(); // Fetch the stored printers when the page loads
  }

  Future<void> _getStoredPrinters() async {
    final List<PrinterModel> storedPrinters = await DatabaseHelper.instance
        .getAllPrinters();
    // Debugging statement to check if printers were retrieved
    print('Stored Printers: ${storedPrinters.length} printers found.');

    if (storedPrinters.isNotEmpty) {
      setState(() {
        printers = storedPrinters;
      });
    } else {
      print('No printers stored in the database.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stored Printers'),
      ),
      body: printers.isEmpty
          ? Center(child: Text('No printers stored in the database.'))
          : ListView.builder(
        itemCount: printers.length,
        itemBuilder: (context, index) {
          final printer = printers[index];
          return ListTile(
            title: Text(printer.name),
            subtitle: Text('Printer: ${printer.category}, ID: ${printer
                .printerId}, Status: ${printer.isMain == true
                ? 'Main Printer'
                : 'Secondary Printer'}'),
            trailing: printer.isMain == true
                ? Icon(Icons.radio_button_checked, color: Colors.green)
                : Icon(Icons.radio_button_off),
          );
        },
      ),
    );
  }
}