import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';
import 'dart:typed_data';
import 'package:apptology/nearpay_service.dart';
import 'package:sunmi_printerx/align.dart';
import 'package:sunmi_printerx/printerstatus.dart';
import 'package:apptology/my_intro_page.dart';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:apptology/order_message_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';




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

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(), // or your title widget
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              color: const Color(0xFFC2DA69),
              padding: EdgeInsets.zero, // tighter if you want
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MyIntroPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true, // Enable JavaScript here
            useOnDownloadStart: true, // ✅ Enable download interception

          ),
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true, // Enable hybrid composition to avoid rendering issues
          ),
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },

        onConsoleMessage: (controller, consoleMessage) async {
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

                await OrderMessageHandler.printToPrinter(
                  context: context,
                  printer: printer,
                  isitreceipt: false,
                  categoryId: printername,
                  casherName: cashiername,
                  orderNumber: orderNumber,
                  orderlines: orderlineParts.cast<List<String>>(),
                );// Cast to List<List<String>>
              } else {
                print("No printer or orderlines found for the order.");
              }
              // Clear the order details after completion
              orders.remove("currentOrder");
            }
          }
          // Handle print_completed message
          if (message.contains("apptology:print_completed")) {
            await OrderMessageHandler.printToPrinter(
              context: context,
              printer: printer,
              isitreceipt: true,
              categoryId: 'main',
              casherName: '',
              orderNumber: '',
              orderlines: [],
            );
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


}