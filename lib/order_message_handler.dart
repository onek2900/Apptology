import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printerstatus.dart';
import 'database/database_helper.dart';
import 'models/printer_model.dart';
import 'nearpay_service.dart';

class OrderMessageHandler {
  final NearpayService nearpayService;
  final SunmiPrinterX printer;
  final BuildContext context;
  final Map<String, Map<String, dynamic>> _orders = {};

  OrderMessageHandler({
    required this.nearpayService,
    required this.printer,
    required this.context,
  });

  Future<void> _printToPrinter(
      bool isitreceipt,
      String categoryId,
      String cashiername,
      String orderNumber,
      List<List<String>> orderlines) async {
    StringBuffer receipt = StringBuffer()
      ..writeln('Order Receipt')
      ..writeln('Casher name: $cashiername')
      ..writeln('Printer name: $categoryId')
      ..writeln('Order Number: $orderNumber')
      ..writeln('--------------------------------')
      ..writeln('Product          Quantity');
    for (var line in orderlines) {
      if (line.length == 3) {
        String productName = line[0];
        String quantity = line[1];
        String customernote = line[2];
        receipt.writeln('$productName        $quantity');
        if (customernote != 'undefined' && customernote.trim().isNotEmpty) {
          receipt.writeln(customernote);
        }
      } else {
        print('Invalid order line format: $line');
      }
    }

    PrinterModel? selectedPrinter =
        await DatabaseHelper.instance.getPrinterByCategory(categoryId);
    if (selectedPrinter == null) {
      print("No printer found for category: $categoryId.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No printer found for category: $categoryId.")),
      );
      return;
    }

    try {
      PrinterStatus status =
          await printer.getPrinterStatus(selectedPrinter.printerId);
      print('Printer Status: $status');

      if (status != PrinterStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${selectedPrinter.name} Printer is not ready.")),
        );
        return;
      }

      if (isitreceipt == false) {
        await printer.printEscPosCommands(selectedPrinter.printerId,
            Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]));
      } else {
        await printer.openCashDrawer(selectedPrinter.printerId);
      }
    } catch (e) {
      print('Error during printing: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  void handleMessage(String message) {
    // Check for "Order Start"
    if (message.contains("Order Start")) {
      print("Order has started.");
    }

    // Check for printer information
    if (message.contains("Printer: ")) {
      String printername = message.split("Printer: ")[1].trim();
      if (_orders.containsKey("currentOrder")) {
        _orders["currentOrder"]!["printername"] = printername;
      } else {
        _orders["currentOrder"] = {"printername": printername};
      }
    }

    // Check for cashier information
    if (message.contains("Cashier: ")) {
      String cashiername = message.split("Cashier: ")[1].trim();
      _orders["currentOrder"]?["cashiername"] = cashiername;
    }

    // Check for order number
    if (message.contains("Order Number: ")) {
      String orderNumber = message.split("Order Number: ")[1].trim();
      _orders["currentOrder"]?["orderNumber"] = orderNumber;
    }

    // Check for order line details (products)
    if (message.contains("OrderlinesQTY:")) {
      String orderlineDetails = message.split("OrderlinesQTY:")[1].trim();
      List<String> orderlineParts = orderlineDetails.split(":");
      if (orderlineParts.length == 3) {
        _orders["currentOrder"]?["orderlines"] ??= [];
        _orders["currentOrder"]!["orderlines"].add(orderlineParts);
      } else {
        print("Invalid order line format: $orderlineParts");
      }
    }

    // Check if the order is completed
    if (message.contains("Order Completed")) {
      Map<String, dynamic>? currentOrder = _orders["currentOrder"];
      if (currentOrder != null) {
        String printername = currentOrder["printername"];
        String cashiername = currentOrder["cashiername"];
        String orderNumber = currentOrder["orderNumber"];
        List<dynamic>? orderlineParts = currentOrder["orderlines"];
        if (orderlineParts != null) {
          _printToPrinter(
              false,
              printername,
              cashiername,
              orderNumber,
              orderlineParts.cast<List<String>>());
        } else {
          print("No printer or orderlines found for the order.");
        }
        _orders.remove("currentOrder");
      }
    }

    // Handle print_completed message
    if (message.contains("apptology:print_completed")) {
      _printToPrinter(true, 'main', '', '', []);
    }

    // Handle nearpay message
    if (message.contains("nearpay:")) {
      String paymentdetails = message.split(":")[2].trim();
      double amountdouble = double.parse(paymentdetails);
      int amountint = (amountdouble * 100).toInt();
      nearpayService.makePurchase(
          amount: amountint, customerReferenceNumber: '123');
    }
  }
}

