import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printer.dart';
import 'database/database_helper.dart';
import 'models/printer_model.dart';

class PrinterManagementPage extends StatefulWidget {
  @override
  _PrinterManagementPageState createState() => _PrinterManagementPageState();
}

class _PrinterManagementPageState extends State<PrinterManagementPage> {
  List<Printer> printerList = [];
  SunmiPrinterX printer = SunmiPrinterX();
  List<TextEditingController> categoryControllers = []; // Controllers for category text fields

  @override
  void initState() {
    super.initState();
    _getPrinters(); // Fetch printers when the app starts
  }

  Future<void> _getPrinters() async {
    try {
      final List<Printer> printers = await printer.getPrinters();
      setState(() {
        printerList = printers;
        categoryControllers = List.generate(
            printers.length, (_) => TextEditingController()); // Initialize controllers for categories
      });
    } on PlatformException catch (e) {
      setState(() {
        printerList = [];
        print("Failed to get printers: '${e.message}'.");
      });
    }
  }

  // Store a single printer in the database
  Future<void> _storePrinterInDatabase(Printer printer, String category) async {
    PrinterModel printerModel = PrinterModel(
      name: printer.name,
      category: category,
    );

    await DatabaseHelper.instance.insertPrinter(printerModel);
    print('Printer saved in the database: ${printer.name}');
  }

  // Delete all existing printers and then store the new ones
  Future<void> _storeAllPrintersInDatabase() async {
    // First, delete all existing printers
    await DatabaseHelper.instance.deleteAllPrinters();

    // Now store the current list of printers
    for (int i = 0; i < printerList.length; i++) {
      final printer = printerList[i];
      final category = categoryControllers[i].text;

      if (category.isNotEmpty) {
        await _storePrinterInDatabase(printer, category);
      } else {
        print('Category is empty for printer: ${printer.name}');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printers saved in the database')),
    );
  }

  // Fetch all printers stored in the database
  Future<void> _displayStoredPrinters() async {
    List<PrinterModel> storedPrinters = await DatabaseHelper.instance.getPrinters();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stored Printers'),
          content: Container(
            width: double.maxFinite,
            child: storedPrinters.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              itemCount: storedPrinters.length,
              itemBuilder: (context, index) {
                final printer = storedPrinters[index];
                return ListTile(
                  title: Text(printer.name ?? 'Unknown Printer'),
                  subtitle: Text('Category: ${printer.category ?? 'No category'}'),
                );
              },
            )
                : Text('No printers stored in the database.'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testPrintAndOpenDrawer(Printer printer, String category) async {
    try {
      // Send a sample text to the selected printer
      await printer.printText('Sample Test Print\n\n\n\n\n');
      print('Test print sent to ${printer.name}');

      // Open the cash drawer for the selected printer
      await printer.openCashDrawer(); // Correct method to open cash drawer
      print('Cash drawer opened for ${printer.name}');

      // Store the printer in the database after printing
      await _storePrinterInDatabase(printer, category);
    } catch (e) {
      print('Failed to print or open drawer for ${printer.name}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Printer Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _getPrinters, // Fetch printers on button press
              child: Text('Refresh Printer List'),
            ),
            SizedBox(height: 20),
            if (printerList.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Category',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Printer',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Test Print',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      printerList.length,
                          (index) {
                        Printer printer = printerList[index]; // This is the selected printer for this row

                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              // Text field to manually enter category
                              TextField(
                                controller: categoryControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Enter category',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(printer.name ?? 'Unknown Printer'),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  final category = categoryControllers[index].text;
                                  _testPrintAndOpenDrawer(printer, category); // Print and open drawer for this specific printer and store it in the database
                                },
                                child: Text('Print Test'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Text('No printers found'),
            SizedBox(height: 20),
            // Place the two buttons in a Row to display them side by side
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the row horizontally
              children: [
                ElevatedButton(
                  onPressed: _storeAllPrintersInDatabase,
                  child: Text('Save Printers'),
                ),
                SizedBox(width: 20), // Add space between the buttons
                ElevatedButton(
                  onPressed: _displayStoredPrinters,
                  child: Text('Show Existing Printers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
