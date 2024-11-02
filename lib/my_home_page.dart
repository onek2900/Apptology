import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';
import 'dart:typed_data';
import 'package:postology/nearpay_service.dart';
import 'package:sunmi_printerx/align.dart';
import 'package:sunmi_printerx/printerstatus.dart';
import 'package:postology/my_intro_page.dart';






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
            if (orderlineParts.length == 3) {
              if (orders.containsKey("currentOrder")) {
                orders["currentOrder"]!["orderlines"] ??= [];
                orders["currentOrder"]!["orderlines"].add(orderlineParts);
              }
            } else {
              print("Invalid order line format: $orderlineParts");
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
          if (message.contains("postology:print_completed")) {
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

  Future<void> _printToPrinter(bool isitreceipt, String categoryId,
      String _Cashername, String _ordernumer,
      List<List<String>> orderlines) async {

    // Prepare a buffer for the content to be printed
    StringBuffer contentToPrint = StringBuffer();
    StringBuffer contentToPrinttitle = StringBuffer();
    List<String> orderline = ['',''];

    // Iterate over the order lines and format them accordingly
    contentToPrinttitle.writeln("Order Receipt");
    contentToPrinttitle.writeln("Casher name: $_Cashername");
    contentToPrinttitle.writeln("Printer name: $categoryId");
    contentToPrinttitle.writeln("Order Number: $_ordernumer");
    contentToPrinttitle.writeln("--------------------------------");

    // Check for selected printer
    PrinterModel? selectedPrinter = await DatabaseHelper.instance
        .getPrinterByCategory(categoryId);
    if (selectedPrinter == null) {
      print("No printer found for category: $categoryId.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No printer found for category: $categoryId.")),
      );
      return;
    }

    print("Printer Name is selected: ${selectedPrinter.name}");
    print("Printer ID is selected: ${selectedPrinter.printerId}");

    print("test is below \n");


    try {
      // Check if the printer SDK's printer object is initialized
      if (printer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Printer SDK is not initialized.")),
        );
        return;
      }
      PrinterStatus status = await printer.getPrinterStatus(selectedPrinter.printerId);
      print('Printer Status: $status');

      if (status != PrinterStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${selectedPrinter.name} Printer is not ready.")),
        );
        return;
      }
      // Check if it's a receipt or a normal print task
      if (isitreceipt == false) {

        await printer.printText(
          selectedPrinter.printerId,
          contentToPrinttitle.toString(),
          textWidthRatio: 0, // Adjust text size
          textHeightRatio: 0, // Adjust text size
          bold: true,
        );
        await printer.printTexts(
          selectedPrinter.printerId,
          ['Name','Quantity'],
          columnWidths: [2,1], // Adjust text size
          columnAligns: [alignFromString('CENTER')
            ,alignFromString('RIGHT')], // Adjust text size
        );

        for (orderline in orderlines) {
          if (orderline.length == 3) {
            String productName = orderline[0];
            String quantity = orderline[1];
            String customernote = orderline[2];

            await printer.printTexts(
              selectedPrinter.printerId,
              [productName,quantity],
              columnWidths: [2,1], // Adjust text size
              columnAligns: [alignFromString('LEFT')
                ,alignFromString('RIGHT'),], // Adjust text size
            );

            await printer.printTexts(
              selectedPrinter.printerId,
              [customernote],
              columnWidths: [1], // Adjust text size
              columnAligns: [alignFromString('CENTER'),], // Adjust text size
            );

          } else {
            print("Invalid order line format: $orderline");
          }
        }

        print('Printed to printer: ${selectedPrinter
            .name} for category ${categoryId} \n${contentToPrint.toString()}');

        await printer.printEscPosCommands(selectedPrinter.printerId,
            Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]));
      } else {
        if (status != PrinterStatus.ready) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${selectedPrinter.name} Printer is not ready.")),
          );
          return;
        }
        print("Opening cash drawer for category: $categoryId");
        await printer.openCashDrawer(selectedPrinter.printerId);
        print('Cash drawer opened successfully.');
      }
    } catch (e) {

      print('Error during printing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e'))
      );
    }
  }


}
