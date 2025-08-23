// lib/order_message_handler.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/printerstatus.dart';

import '../models/printer_model.dart';
import '../database/database_helper.dart';

/// 80mm printers commonly handle ~48 chars; tweak if alignment drifts.
const int kCharsPerLine = 48;
const String kNotePrefix = 'CN: ';

/// Format "<left> ... <right>" so <right> is right-aligned.
String _formatLine(String left, String right, {int width = kCharsPerLine}) {
  left = left.replaceAll('\n', ' ');
  right = right.replaceAll('\n', ' ');

  final int rightLen = right.length;
  final int leftMax = width - rightLen - 1; // keep at least one space

  if (leftMax < 1) return '$left $right';

  final String leftTrim =
  left.length > leftMax ? '${left.substring(0, leftMax - 1)}…' : left;

  final int spaces = width - rightLen - leftTrim.length;
  return '$leftTrim${' ' * spaces}$right';
}

/// Normalize for comparison: lowercased, strip spaces/punct,
/// remove common Arabic diacritics (tashkeel).
String _normalizeForCompare(String s) {
  final noDiacritics = s.replaceAll(
    RegExp(r'[\u0617-\u061A\u064B-\u0652\u0670\u06D6-\u06ED]'),
    '',
  );
  final lower = noDiacritics.toLowerCase();
  return lower.replaceAll(RegExp(r'[^A-Za-z0-9\u0600-\u06FF]+'), '');
}

/// Accepts "EN|AR" or plain "Name".
/// Prefers AR as primary if present. If secondary equals primary after
/// normalization, it is dropped.
List<String> _splitDualName(String s) {
  final parts = s.split('|');
  final en = parts.isNotEmpty ? parts[0].trim() : '';
  final ar = parts.length > 1 ? parts[1].trim() : '';
  String primary = ar.isNotEmpty ? ar : en;
  String secondary = ar.isNotEmpty ? en : '';

  if (secondary.isNotEmpty &&
      _normalizeForCompare(primary) == _normalizeForCompare(secondary)) {
    secondary = ''; // ignore duplicate secondary
  }
  return [primary, secondary];
}

bool _hasNote(String? s) =>
    s != null && s.trim().isNotEmpty && s.trim() != 'undefined';

/// Simple datetime formatter: "YYYY-MM-DD HH:MM:SS"
String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}

class OrderMessageHandler {
  /// Prints an order to a Sunmi printer by category.
  ///
  /// When [isitreceipt] is true, only opens the cash drawer.
  static Future<void> printToPrinter({
    required BuildContext context,
    required SunmiPrinterX printer,
    required bool isitreceipt,
    required String categoryId,
    required String casherName,
    required String orderNumber,
    required List<List<String>> orderlines,
  }) async {
    final PrinterModel? selectedPrinter =
    await DatabaseHelper.instance.getPrinterByCategory(categoryId);

    if (selectedPrinter == null) {
      _snack(context, 'No printer found for category: $categoryId.');
      return;
    }

    try {
      final PrinterStatus status =
      await printer.getPrinterStatus(selectedPrinter.printerId);
      if (status != PrinterStatus.ready) {
        _snack(context, '${selectedPrinter.name} is not ready (status: $status).');
        return;
      }

      // Cash-drawer-only path
      if (isitreceipt) {
        await printer.openCashDrawer(selectedPrinter.printerId);
        await printer.printEscPosCommands(
          selectedPrinter.printerId,
          Uint8List.fromList([0x1B, 0x64, 0x01]), // feed 1 line
        );
        return;
      }

      // ---- Header ----
      final now = DateTime.now();
      final String formattedDT = _formatDateTime(now);

      final StringBuffer header = StringBuffer()
        ..writeln('Order Receipt')
        ..writeln('Date: $formattedDT')
        ..writeln('Cashier: $casherName')
        ..writeln('Printer: $categoryId')
        ..writeln('Order #: $orderNumber')
        ..writeln('--------------------------------');

      await printer.printText(
        selectedPrinter.printerId,
        header.toString(),
        textWidthRatio: 0,
        textHeightRatio: 0,
        bold: true,
      );

      // ---- Column header ----
      await printer.printText(
        selectedPrinter.printerId,
        _formatLine('Product', 'Qty'),
      );

      // ---- Items (primary + secondary on SAME line) ----
      for (final line in orderlines) {
        if (line.length < 2) {
          // ignore: avoid_print
          print('Invalid order line format: $line');
          continue;
        }

        final String rawName  = line[0]; // may be "EN|AR" or just a name
        final String quantity = line[1].toString();
        final String? noteRaw = (line.length > 2) ? line[2] : null;

        final names = _splitDualName(rawName);
        final String primary   = names[0]; // Arabic preferred if provided
        final String secondary = names[1]; // English if not duplicate

        // JOIN primary + secondary on the SAME left field
        final String left = secondary.isNotEmpty
            ? '$primary | $secondary'
            : primary;

        // one line: "<primary | secondary> ................. <qty>"
        await printer.printText(
          selectedPrinter.printerId,
          _formatLine(left, quantity),
        );

        // optional note as "CN: ..." on the next line
        if (_hasNote(noteRaw)) {
          await printer.printText(
            selectedPrinter.printerId,
            '  $kNotePrefix${noteRaw!.trim()}',
          );
        }
      }

      // ---- Feed & cut ----
      await printer.printEscPosCommands(
        selectedPrinter.printerId,
        Uint8List.fromList([0x1B, 0x64, 0x02]), // feed 2 lines
      );
      await printer.printEscPosCommands(
        selectedPrinter.printerId,
        Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]), // partial cut
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error during printing: $e');
      _snack(context, 'Failed to print: $e');
    }
  }

  static void _snack(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
