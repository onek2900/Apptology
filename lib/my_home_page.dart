import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:apptology/nearpay_service.dart';
import 'package:apptology/my_intro_page.dart';
import 'order_message_handler.dart';



class MyHomePage extends StatefulWidget {
  final String url;

  MyHomePage({required this.url});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SunmiPrinterX printer = SunmiPrinterX();
  InAppWebViewController? webViewController;
  final NearpayService nearpayService = NearpayService(); // Create an instance of your service class
  late final OrderMessageHandler messageHandler;

  @override
  void initState() {
    super.initState();
    printer.getPrinters(); // Initialize the table from the database
    messageHandler = OrderMessageHandler(
      nearpayService: nearpayService,
      printer: printer,
      context: context,
    );
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

        onConsoleMessage: (controller, consoleMessage) {
          String message = consoleMessage.message;
          messageHandler.handleMessage(message);
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

