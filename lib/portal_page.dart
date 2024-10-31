import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:postology/nearpay_service.dart'; // Import your Nearpay service


class PortalPage extends StatefulWidget {
  final String url;

  const PortalPage({Key? key, required this.url}) : super(key: key);

  @override
  _PortalPageState createState() => _PortalPageState();
}

class _PortalPageState extends State<PortalPage> {
  SunmiPrinterX printer = SunmiPrinterX();
  InAppWebViewController? webViewController;
  final NearpayService nearpayService = NearpayService(); // Instance of your Nearpay service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portal'),
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

          // Handle various console messages
          if (message.contains("postology:print_completed")) {
            _printToPrinter(true, 'main', '', '', []); // Open cash drawer
          } else if (message.contains("nearpay:")) {
            // Handle Nearpay messages
            String paymentdetails = message.split(":")[2].trim();
            double amountdouble = double.parse(paymentdetails);
            int amountint = (amountdouble * 100).toInt();
            nearpayService.makePurchase(amount: amountint, customerReferenceNumber: '123');
          } else {
            // Other console message handling
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
    // Implementation remains unchanged from your previous code
    // Ensure existing functionality for printing and opening cash drawer is preserved
  }
}
