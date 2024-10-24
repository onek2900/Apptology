import 'dart:typed_data';

import 'package:sunmi_printerx/align.dart';
import 'package:sunmi_printerx/printer.dart';
import 'package:sunmi_printerx/printerstatus.dart';

import 'sunmi_printerx_platform_interface.dart';

class SunmiPrinterX {
  Future<List<Printer>> getPrinters() async {
    return (await SunmiPrinterXPlatform.instance.getPrinters())
        .map((printerData) {
      var id = printerData['id'];
      final printer = Printer(
        name: printerData['name'],
        status: printerStatusFromString(printerData['status']),
        hot: printerData['hot'],
        version: printerData['version'],
        id: id,
        cutter: printerData['cutter'],
        density: printerData['density'],
        distance: printerData['distance'],
        gray: printerData['gray'],
        paper: printerData['paper'],
        type: printerData['type'],
        getStatus: () => _getPrinterStatus(id),
        openCashDrawer: () => _openCashDrawer(id),
        isCashDrawerOpen: () => _isCashDrawerOpen(id),
        printEscPosCommands: (commands) => _printEscPosCommands(id, commands),
        waitForCashDrawerClose: () => _waitForCashDrawerClose(id),
        setAlign: (align) => _setAlign(id, align),
        printText: (text,
            {textWidthRatio = 0,
              textHeightRatio = 0,
              textSpace = 0,
              bold = false,
              underline = false,
              strikethrough = false,
              italic = false,
              align = Align.left}) =>
            printText(id, text,
                textWidthRatio: textWidthRatio,
                textHeightRatio: textHeightRatio,
                textSpace: textSpace,
                bold: bold,
                underline: underline,
                strikethrough: strikethrough,
                italic: italic,
                align: align),
        autoOut: () => autoOut(id),
        printQrCode: (data, {dot = 3, align = Align.center}) =>
            printQrCode(id, data, dot: dot, align: align),
        printTexts: (texts,
            {columnWidths = const [], columnAligns = const []}) =>
            printTexts(id, texts,
                columnWidths: columnWidths, columnAligns: columnAligns),
        addText: (text,
            {textWidthRatio = 0,
              textHeightRatio = 0,
              textSpace = 0,
              bold = false,
              underline = false,
              strikethrough = false,
              italic = false,
              align = Align.left}) =>
            addText(id, text,
                textWidthRatio: textWidthRatio,
                textHeightRatio: textHeightRatio,
                textSpace: textSpace,
                bold: bold,
                underline: underline,
                strikethrough: strikethrough,
                italic: italic,
                align: align),
      );
      return printer;
    }).toList();
  }

  Future<PrinterStatus> _getPrinterStatus(String printerId) async {
    final result =
    await SunmiPrinterXPlatform.instance.getPrinterStatus(printerId);
    return printerStatusFromString(result);
  }

  Future<PrinterStatus> getPrinterStatus(String printerId) async {
    final result =
    await SunmiPrinterXPlatform.instance.getPrinterStatus(printerId);
    return printerStatusFromString(result);
  }

  Future<bool> _openCashDrawer(String printerId) {
    return SunmiPrinterXPlatform.instance.openCashDrawer(printerId);
  }


  Future<bool> _isCashDrawerOpen(String printerId) {
    return SunmiPrinterXPlatform.instance.isCashDrawerOpen(printerId);
  }

  Future<void> _printEscPosCommands(String printerId, Uint8List commands) {
    return SunmiPrinterXPlatform.instance
        .printEscPosCommands(printerId, commands);
  }

  Future<void> printEscPosCommands(String printerId, Uint8List commands) {
    return SunmiPrinterXPlatform.instance
        .printEscPosCommands(printerId, commands);
  }

  Future<bool> openCashDrawer(String printerId) async {
    // Trigger the cash drawer opening using the specific method.
    await SunmiPrinterXPlatform.instance.openCashDrawer(printerId);

    // Now send the ESC/POS command for cutting the paper
    try {
      await _printEscPosCommands(printerId, Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]));
      return true;  // Return true if the command was successful
    } catch (e) {
      print("Error while opening cash drawer or cutting paper: $e");
      return false; // Return false if something went wrong
    }
  }

  Future<void> _waitForCashDrawerClose(String printerId,
      {Duration pollInterval = const Duration(milliseconds: 300)}) {
    return Future<void>.delayed(pollInterval, () {
      return _isCashDrawerOpen(printerId).then((isOpen) {
        if (isOpen) {
          return _waitForCashDrawerClose(printerId, pollInterval: pollInterval);
        }
      });
    });
  }

  Future<void> _setAlign(String printerId, Align align) {
    return SunmiPrinterXPlatform.instance.setAlign(printerId, align);
  }

  Future<void> printText(String printerId, String text,
      {int textWidthRatio = 0,
        int textHeightRatio = 0,
        int textSpace = 0,
        bool bold = false,
        bool underline = false,
        bool strikethrough = false,
        bool italic = false,
        Align align = Align.left}) async {
    // Ensure that text printing is awaited
    await SunmiPrinterXPlatform.instance.printText(
      printerId,
      text,
      textWidthRatio: textWidthRatio,
      textHeightRatio: textHeightRatio,
      textSpace: textSpace,
      bold: bold,
      underline: underline,
      strikethrough: strikethrough,
      italic: italic,
      align: align,
    );
  }


  Future<void> autoOut(String printerId) {
    return SunmiPrinterXPlatform.instance.autoOut(printerId);
  }

  Future<void> printQrCode(String printerId, String data,
      {int dot = 3, Align align = Align.center}) {
    return SunmiPrinterXPlatform.instance
        .printQrCode(printerId, data, dot: dot, align: align);
  }

  Future<void> printTexts(String printerId, List<String> texts,
      {List<int> columnWidths = const [], List<Align> columnAligns = const []}) async {

    // Await the text printing to ensure it completes before moving to the next command
    await SunmiPrinterXPlatform.instance.printTexts(
        printerId,
        texts,
        columnWidths: columnWidths,
        columnAligns: columnAligns
    );

  }


  Future<void> addText(String printerId, String text,
      {int textWidthRatio = 0,
        int textHeightRatio = 0,
        int textSpace = 0,
        bool bold = false,
        bool underline = false,
        bool strikethrough = false,
        bool italic = false,
        Align align = Align.left}) {
    return SunmiPrinterXPlatform.instance.addText(printerId, text,
        textWidthRatio: textWidthRatio,
        textHeightRatio: textHeightRatio,
        textSpace: textSpace,
        bold: bold,
        underline: underline,
        strikethrough: strikethrough,
        italic: italic,
        align: align);
  }
}
