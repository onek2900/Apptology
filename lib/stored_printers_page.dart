import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/printer_model.dart';

class StoredPrintersPage extends StatefulWidget {
  @override
  _StoredPrintersPageState createState() => _StoredPrintersPageState();
}

class _StoredPrintersPageState extends State<StoredPrintersPage> {
  List<PrinterModel> storedPrinters = [];

  @override
  void initState() {
    super.initState();
    _loadStoredPrinters();
  }

  Future<void> _loadStoredPrinters() async {
    final List<PrinterModel> printers = await DatabaseHelper.instance.getPrinters();
    setState(() {
      storedPrinters = printers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stored Printers'),
      ),
      body: storedPrinters.isEmpty
          ? Center(child: Text('No printers stored in the database.'))
          : ListView.builder(
        itemCount: storedPrinters.length,
        itemBuilder: (context, index) {
          final printer = storedPrinters[index];
          return ListTile(
            title: Text(printer.name),
            subtitle: Text('Category: ${printer.category}'),
          );
        },
      ),
    );
  }
}
