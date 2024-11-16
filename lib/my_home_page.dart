import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';
import 'dart:typed_data';
import 'package:apptology/nearpay_service.dart';
import 'package:sunmi_printerx/align.dart';
import 'package:sunmi_printerx/printerstatus.dart';
import 'package:apptology/my_intro_page.dart';






class MyHomePage extends StatefulWidget {
  final String url;

  MyHomePage({required this.url});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SunmiPrinterX printer = SunmiPrinterX();
  InAppWebViewController? webViewController;
  bool isitreceipt = false;
  final NearpayService nearpayService = NearpayService(); // Create an instance of your service class
  // Create a map to store order data by order number
  Map<String, Map<String, dynamic>> orders = {};
  List<String> orderlineParts = [];

  @override
  void initState() {
    super.initState();
    printer.getPrinters();// Initialize the table from the database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
automaticallyImplyLeading: false,
        actions: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  color: Color(0xFFC2DA69),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyIntroPage()));
                  },
                ),
              ],
            ),
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true, // Enable JavaScript here
          ),
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true, // Enable hybrid composition to avoid rendering issues
          ),
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onConsoleMessage: (controller, consoleMessage) {
          String message = consoleMessage.message;
          // Check for "Order Start"
          if (message.contains("Order Start")) {
            print("Order has started.");
          }
          // Check for printer information
          if (message.contains("Printer: ")) {
            String printername = message.split("Printer: ")[1].trim();

            // Temporarily store the printer info for this order
            if (orders.containsKey("currentOrder")) {
              orders["currentOrder"]!["printername"] = printername;
            } else {
              orders["currentOrder"] = {"printername": printername};
            }
          }
          // Check for cashier information
          if (message.contains("Cashier: ")) {
            String cashiername = message.split("Cashier: ")[1].trim();
            // Store the cashier name for this order
            orders["currentOrder"]?["cashiername"] = cashiername;
          }
          // Check for order number
          if (message.contains("Order Number: ")) {
            String orderNumber = message.split("Order Number: ")[1].trim();

            // Store the order number and ensure we are keeping track of this specific order
            orders["currentOrder"]?["orderNumber"] = orderNumber;
          }
          // Check for order line details (products) with the new format
          if (message.contains("OrderlinesQTY:")) {
            // Split the message using ":" as the separator
            String orderlineDetails = message.split("OrderlinesQTY:")[1].trim();
            List<String> orderlineParts = orderlineDetails.split(":");
            // Store the orderline parts for this order if correctly formatted
            if (orderlineParts.length == 4) {
              if (orders.containsKey("currentOrder")) {
                orders["currentOrder"]!["orderlines"] ??= [];
                orders["currentOrder"]!["orderlines"].add(orderlineParts);
              }
            } else {

              print("Invalid order line format11: $orderlineParts");
            }
          }
          // Check if the order is completed
          if (message.contains("Order Completed")) {
            // Retrieve stored details
            Map<String, dynamic>? currentOrder = orders["currentOrder"];
            if (currentOrder != null) {
              String printername = currentOrder["printername"];
              String cashiername = currentOrder["cashiername"];
              String orderNumber = currentOrder["orderNumber"];
              List<dynamic>? orderlineParts = currentOrder["orderlines"];
              // Now print to printer if the printer name exists
              if (orderlineParts != null) {
                _printToPrinter(false, printername, cashiername, orderNumber,
                    orderlineParts.cast<
                        List<String>>()); // Cast to List<List<String>>
              } else {
                print("No printer or orderlines found for the order.");
              }
              // Clear the order details after completion
              orders.remove("currentOrder");
            }
          }
          // Handle print_completed message
          if (message.contains("apptology:print_completed")) {
            _printToPrinter(
                true, 'main', '', '', []); // Just opening the cash drawer
          }
          // Handle print_completed message
          if (message.contains("nearpay:")) {
            String paymentdetails = message.split(":")[2].trim();
            double amountdouble = double.parse(paymentdetails);
            int amountint = (amountdouble * 100).toInt();
            nearpayService.makePurchase(amount: amountint, customerReferenceNumber: '123'); // Just opening the cash drawer
          }
        },
        onLoadStop: (controller, url) async {
          // Inject CSS for printing with a white background
          await controller.evaluateJavascript(source: '''
            var style = document.createElement('style');
            style.innerHTML = `
              @media print {
                body {
                  background-color: white !important;
                  color: black !important;
                }
                * {
                  box-shadow: none !important;
                  background: none !important;
                }
                .no-print {
                  display: none !important;
                }
              }
            `;
            document.head.appendChild(style);
          ''');
        },
      ),
    );
  }

  Future<void> _ArbEscPosCommands(String printerId, Uint8List commands) async {
    try {
      await printer.printEscPosCommands(printerId, commands);
      print('ESC/POS commands sent successfully.');
    } catch (e) {
      print('Error printing ESC/POS commands: $e');
      // Handle error as needed
    }
  }


  Future<void> _printToPrinter(bool isitreceipt, String categoryId,
      String _Cashername, String _ordernumer,
      List<List<String>> orderlines) async {
    // Ensure the printer is selected
    PrinterModel? selectedPrinter = await DatabaseHelper.instance
        .getPrinterByCategory(categoryId);
    if (selectedPrinter == null) {
      print("No printer found for category: $categoryId.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No printer found for category: $categoryId.")),
      );
      return;
    }

    try {
      PrinterStatus status = await printer.getPrinterStatus(selectedPrinter.printerId);
      if (status != PrinterStatus.ready) {
        print("Warning: Printer is not ready.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Printer is not ready.")),
        );
        return;
      }

      // Group orders by the first value (orderlineParts[0])
      Map<String, List<List<String>>> groupedOrders = {};
      for (var orderline in orderlines) {
        if (orderline.isNotEmpty) {
          String groupKey = orderline[0]; // Use the first value as the key
          groupedOrders[groupKey] ??= [];
          groupedOrders[groupKey]!.add(orderline);
        }
      }

      // Print each group on a separate paper
      for (var groupKey in groupedOrders.keys) {
        List<List<String>> groupOrderlines = groupedOrders[groupKey]!;

        // Prepare header and content for this group
        StringBuffer contentToPrint = StringBuffer();
        contentToPrint.writeln("Order Receipt");
        contentToPrint.writeln("Cashier: $_Cashername");
        contentToPrint.writeln("Printer: ${selectedPrinter.name}");
        contentToPrint.writeln("Order Number: $_ordernumer");
        contentToPrint.writeln("Group: $groupKey");
        contentToPrint.writeln("--------------------------------");

        int productNameWidth = 30; // Adjust based on printer width
        int quantityWidth = 10;    // Adjust as needed

        // Add table headers
        contentToPrint.writeln(
          'Name'.padRight(productNameWidth) + 'Qty'.padLeft(quantityWidth),
        );
        contentToPrint.writeln(''.padRight(productNameWidth + quantityWidth, '-'));

        // Add the grouped orderlines
        for (var orderline in groupOrderlines) {
          if (orderline.length >= 4) {
            String productName = orderline[1];
            String quantity = orderline[2];
            String customernote = orderline[3];

            String formattedLine = productName.padRight(productNameWidth) + quantity.padLeft(quantityWidth);

            contentToPrint.writeln(formattedLine);
            contentToPrint.writeln(customernote.padLeft(productNameWidth + quantityWidth));
          } else {
            print("Invalid order line format: $orderline");
          }
        }

        // Print the content
        if (isitreceipt == false) {
          await printer.printText(
            selectedPrinter.printerId,
            contentToPrint.toString(),
            textWidthRatio: 0,
            textHeightRatio: 0,
            bold: false,
          );
          await printer.printEscPosCommands(
            selectedPrinter.printerId,
            Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]),
          ); // Form feed to eject paper
        } else {
          await printer.openCashDrawer(selectedPrinter.printerId);
          print('Cash drawer opened successfully.');
        }
      }

    } catch (e) {
      print('Error during printing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: $e')),
      );
    }
  }



}
