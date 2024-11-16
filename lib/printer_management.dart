import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart'; // Import only sunmi_printerx.dart
import 'database/database_helper.dart';
import 'models/printer_model.dart';
import 'stored_printers_page.dart'; // Import to show stored printers
import 'package:sunmi_printerx/printer.dart';

class PrinterManagementPage extends StatefulWidget {
  @override
  _PrinterManagementPageState createState() => _PrinterManagementPageState();
}

class _PrinterManagementPageState extends State<PrinterManagementPage> {
  List<PrinterModel> printerList = []; // List of PrinterModel objects
  SunmiPrinterX printer = SunmiPrinterX();
  List<TextEditingController> categoryControllers = [];
  int? selectedMainPrinterIndex;
  bool noDatabase = false; // Track if there is no database

  @override
  void initState() {
    super.initState();
    _initializeTableFromDatabase(); // Initialize the table from the database
  }

  // Method to initialize table from the database or show "No database"
  Future<void> _initializeTableFromDatabase() async {
    try {
      var printersFromDatabase = await DatabaseHelper.instance.getAllPrinters();
      if (printersFromDatabase.isNotEmpty) {
        setState(() {
          // Populate printerList with the PrinterModel objects
          printerList = printersFromDatabase;
          categoryControllers = List.generate(
              printerList.length, (index) => TextEditingController(text: printerList[index].category));
          noDatabase = false; // Data found, no need for "No database" message
        });
      } else {
        setState(() {
          noDatabase = true; // No printers found, show "No database" message
        });
      }
    } catch (e) {
      setState(() {
        noDatabase = true; // Handle database access failure
      });
    }
  }
  Future<void> _getPrinters() async {
    try {
      // Fetch the printers from the SunmiPrinterX API
      final List<Printer> printers = await printer.getPrinters();
      setState(() {
        // Map the list of Printer objects to the PrinterModel list
        printerList = printers.map((p) {
          return PrinterModel(
            name: p.name ?? 'Unknown Printer', // Get the printer name from the Printer object
            category: 'Uncategorized', // You can assign or modify this category based on your logic
            printerId: p.id ?? 'Unknown ID', // Get the printer ID from the Printer object
            isMain: false, // Default value, update based on your main printer logic
          );
        }).toList();

        // Initialize the category controllers
        categoryControllers = List.generate(
          printerList.length,
              (index) => TextEditingController(text: printerList[index].category),
        );

        noDatabase = false; // Data found, no need for "No database" message
      });
    } on PlatformException catch (e) {
      setState(() {
        printerList = [];
        print("Failed to get printers: '${e.message}'.");
      });
    }
  }

  // Store all printers in the database
  Future<void> _storeAllPrintersInDatabase() async {
    try {

      await DatabaseHelper.instance.deleteAllPrinters();
      // Delete previous data
      for (int i = 0; i < printerList.length; i++) {
        PrinterModel printerModel = PrinterModel(
          name: printerList[i].name,
          category: categoryControllers[i].text,
          printerId: printerList[i].printerId,
          isMain: selectedMainPrinterIndex == i, // Set as main if selected
        );


        await DatabaseHelper.instance.insertPrinter(printerModel);
        print('Printer ${printerModel.name} stored in database');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All printers have been stored successfully!')),
      );
    } catch (e) {
      print('Error storing printers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to store printers: $e')),
      );
    }
  }

  // Set the selected printer as the main printer
  Future<void> _setAsMainPrinter(int index) async {
    setState(() {
      selectedMainPrinterIndex = index; // Mark this index as the main printer
    });
  }




  // Perform test print and open the cash drawer
  Future<void> _testPrintAndOpenDrawer(PrinterModel printer1, String category) async {
    try {
      print('Test print sent to printer with ID ${printer1.printerId}');
      await printer.printText(printer1.printerId.toString(),'Sample Test Print\n\n\n\n\n'); // Pass printerId
      // Open the cash drawer using the printer ID
      print('Cash drawer opened for printer with ID ${printer1.printerId}');
      await printer.openCashDrawer(printer1.printerId.toString()); // Pass printerId

    } catch (e) {
      print('Failed to print or open drawer for printer with ID ${printer1.printerId}: $e');
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
            if (noDatabase) ...[
              Text('No database found'),
            ] else if (printerList.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Ensures horizontal scrolling for wide tables
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Printer',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Printer Name',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Printer ID',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Printer Status',
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
                        PrinterModel printer = printerList[index];

                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              TextField(
                                controller: categoryControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Enter category',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(printer.name),
                            ),
                            DataCell(
                              Text(printer.printerId),
                            ),
                            DataCell(
                              Text(printer.isMain ? "Main" : "Secondary"),
                            ),
                            DataCell(
                              Radio<int>(
                                value: index,
                                groupValue: selectedMainPrinterIndex,
                                onChanged: (int? value) {
                                  _setAsMainPrinter(index);
                                },
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  final category = categoryControllers[index].text;
                                  _testPrintAndOpenDrawer(printer, category);
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
                  onPressed: _storeAllPrintersInDatabase, // Store printers when button is pressed
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
