import 'dart:typed_data';
import 'package:sunmi_printerx/sunmi_printerx.dart';

extension SunmiPrinterImageExtension on SunmiPrinterX {
  Future<void> printImage(String printerId, Uint8List bytes) async {
    await bitmap(printerId, bytes);
  }
}
