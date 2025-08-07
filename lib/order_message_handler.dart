// lib/order_message_handler.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printerstatus.dart';
import 'package:sunmi_printerx/align.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';

class OrderMessageHandler {
  static Future<void> printToPrinter({
    required BuildContext context,
    required SunmiPrinterX printer,
    required bool isitreceipt,
    required String categoryId,
    required String casherName,
    required String orderNumber,
    required List<List<String>> orderlines,
  }) async {
    StringBuffer contentToPrinttitle = StringBuffer();
    contentToPrinttitle.writeln("Order Receipt");
    contentToPrinttitle.writeln("Casher name: \$casherName");
    contentToPrinttitle.writeln("Printer name: \$categoryId");
    contentToPrinttitle.writeln("Order Number: \$orderNumber");
    contentToPrinttitle.writeln("--------------------------------");

    PrinterModel? selectedPrinter =
    await DatabaseHelper.instance.getPrinterByCategory(categoryId);
    if (selectedPrinter == null) {
      print("No printer found for category: \$categoryId.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No printer found for category: \$categoryId.")),
      );
      return;
    }

    try {
      PrinterStatus status =
      await printer.getPrinterStatus(selectedPrinter.printerId);
      if (status != PrinterStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${selectedPrinter.name} Printer is not ready.")),
        );
        return;
      }

      if (!isitreceipt) {
        await printer.printText(
          selectedPrinter.printerId,
          contentToPrinttitle.toString(),
          textWidthRatio: 0,
          textHeightRatio: 0,
          bold: true,
        );
        await printer.printTexts(
          selectedPrinter.printerId,
          ['Product', 'Quantity'],
          columnWidths: [2, 1],
          columnAligns: [alignFromString('LEFT'), alignFromString('RIGHT')],
        );

        for (var orderline in orderlines) {
          if (orderline.length == 3) {
            String productName = orderline[0];
            String quantity = orderline[1];
            String customernote =
            orderline[2] == 'undefined' ? '' : orderline[2];

            await printer.printTexts(
              selectedPrinter.printerId,
              [productName, quantity],
              columnWidths: [2, 1],
              columnAligns: [alignFromString('LEFT'), alignFromString('RIGHT')],
            );

            await printer.printTexts(
              selectedPrinter.printerId,
              [customernote],
              columnWidths: [1],
              columnAligns: [alignFromString('CENTER')],
            );
          } else {
            print("Invalid order line format: \$orderline");
          }
        }

        await printer.printEscPosCommands(
          selectedPrinter.printerId,
          Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]),
        );
      } else {
        await printer.openCashDrawer(selectedPrinter.printerId);
        print('Cash drawer opened successfully.');
      }
    } catch (e) {
      print('Error during printing: \$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: \$e')),
      );
    }
  }
}
