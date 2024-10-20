// printer_management.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printer.dart';

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
            printers.length, (_) => TextEditingController()); // Initialize controllers
      });
    } on PlatformException catch (e) {
      setState(() {
        printerList = [];
        print("Failed to get printers: '${e.message}'.");
      });
    }
  }

  Future<void> _testPrintAndOpenDrawer(Printer printer) async {
    try {
      // Send a sample text to the selected printer
      await printer.printText('Sample Test Print\n\n\n\n\n');
      print('Test print sent to ${printer.name}');

      // Open the cash drawer for the selected printer
      await printer.openCashDrawer(); // Correct method to open cash drawer
      print('Cash drawer opened for ${printer.name}');
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
                                  _testPrintAndOpenDrawer(printer); // Print and open drawer for this specific printer
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
          ],
        ),
      ),
    );
  }
}
