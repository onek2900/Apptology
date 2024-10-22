import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printer.dart';
import 'database/database_helper.dart';
import 'models/printer_model.dart';
import 'stored_printers_page.dart'; // Import to show stored printers

class PrinterManagementPage extends StatefulWidget {
  @override
  _PrinterManagementPageState createState() => _PrinterManagementPageState();
}

class _PrinterManagementPageState extends State<PrinterManagementPage> {
  List<Printer> printerList = [];
  SunmiPrinterX printer = SunmiPrinterX();
  List<TextEditingController> categoryControllers = []; // Controllers for category text fields
  int? selectedMainPrinterIndex; // To track which radio button is selected

  @override
  void initState() {
    super.initState();
    _deleteExistingDatabaseAndInitialize(); // This method will delete and reinitialize the database
    _getPrinters(); // Fetch printers when the app starts
  }
// Method to delete the database and initialize it
  Future<void> _deleteExistingDatabaseAndInitialize() async {
    await DatabaseHelper.instance.deleteDatabaseFile(); // Deletes the existing database file
    await DatabaseHelper.instance.database; // Reinitialize the database
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

  // Ensure database is initialized
  Future<void> _initializeDatabase() async {
    await DatabaseHelper.instance.database; // This will ensure the database is initialized
  }

  // Store all printers into the database after clearing the previous entries
  Future<void> _storeAllPrintersInDatabase() async {

    try {
      // Delete all previous entries before adding new ones
      await DatabaseHelper.instance.deleteAllPrinters();

      // Loop through the list of printers and store each one
      for (int i = 0; i < printerList.length; i++) {
        Printer printer = printerList[i];
        String category = categoryControllers[i].text;

        // Ensure category is not empty, set a default if required
        if (category.isEmpty) {
          category = 'Uncategorized'; // Default category if none is provided
        }

        PrinterModel printerModel = PrinterModel(
          name: printer.name!,
          category: category,
          printerId: printer.id!,
          isMain: selectedMainPrinterIndex == i, // Set this as the main printer if selected
        );

        // Insert the printer into the database
        await DatabaseHelper.instance.insertPrinter(printerModel);
        print('Printer ${printer.name} stored in database');
      }

      // Show a success message after storing all printers
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All printers have been stored successfully!')),
      );
    } catch (e) {
      // Handle any errors during storage
      print('Error storing printers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to store printers: $e')),
      );
    }
  }

  // Set the selected printer as the main printer and update the database
  Future<void> _setAsMainPrinter(int index) async {
    setState(() {
      selectedMainPrinterIndex = index; // Mark this index as the main printer
    });
  }

  Future<void> _testPrintAndOpenDrawer(Printer printer1, String category) async {
    try {
      // Send a sample text to the selected printer using sunmi_printerx
      await printer1.printText('Sample Test Print\n\n\n\n\n');
      print('Test print sent to ${printer1.name}');

      // Open the cash drawer for the selected printer using sunmi_printerx
      await printer1.openCashDrawer(); // Correct method to open cash drawer
      print('Cash drawer opened for ${printer1.name}');
    } catch (e) {
      print('Failed to print or open drawer for ${printer1.name}: $e');
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
                          'Main',
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
                              Radio<int>(
                                value: index, // The index of this printer
                                groupValue: selectedMainPrinterIndex, // The selected index
                                onChanged: (int? value) {
                                  _setAsMainPrinter(index); // Set this printer as the main one
                                },
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  final category = categoryControllers[index].text;
                                  _testPrintAndOpenDrawer(printer, category); // Print and open drawer for this specific printer
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _storeAllPrintersInDatabase, // Store printers in the database
                  child: Text('Store Printers'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => StoredPrintersPage()),
                    );
                  },
                  child: Text('Show Stored Printers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
