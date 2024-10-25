import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:postology/printer_management.dart';
import 'package:postology/nearpay_paymentint.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';
import 'dart:typed_data';
import 'package:postology/models/ClearHelper.dart';
import 'package:postology/nearpay_service.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSTology',
       theme: AppTheme.appTheme,
      home: Scaffold(
        body: MyHomePage(selectedIndex: 1, initialUrl: "https://apptologyinc.com"),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int selectedIndex; // Selected index to start with
  final String initialUrl; // Initial URL to set

  const MyHomePage({Key? key, required this.selectedIndex, required this.initialUrl}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;
  late String _url;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _url = widget.initialUrl; // Use the initial URL passed from SettingsPage
  }

  // Define the views for each tab
  final List<Widget> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages.add(PortalPage(url: _url)); // Pass the URL to PortalPage
    _pages.add(SettingsPage(onUrlChanged: (String newUrl) {
      setState(() {
        _url = newUrl; // Update the URL
        _pages[0] = PortalPage(url: _url); // Update PortalPage with new URL
      });
    }));
  }

  // When tapped, switch between the pages
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.web),
            label: 'Portal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PortalPage extends StatefulWidget {
  final String url;

  const PortalPage({Key? key, required this.url}) : super(key: key);

  @override
  _PortalPageState createState() => _PortalPageState();
}
class _PortalPageState extends State<PortalPage> {
  SunmiPrinterX printer = SunmiPrinterX();
  InAppWebViewController? webViewController;
  bool isitreceipt = false;
  final NearpayService nearpayService = NearpayService(); // Create an instance of your service class


  // Create a map to store order data by order number
  Map<String, Map<String, dynamic>> orders = {};
  List<String> orderlineParts = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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

    // Iterate over the order lines and format them accordingly
    contentToPrinttitle.writeln("Order Receipt");
    contentToPrinttitle.writeln("Casher name: $_Cashername");
    contentToPrinttitle.writeln("Printer name: $categoryId");
    contentToPrinttitle.writeln("Order Number: $_ordernumer");

    contentToPrinttitle.writeln("----------------------------");
    contentToPrinttitle.writeln("category\tName\t\t\tquantity");


    for (List<String> orderline in orderlines) {
      if (orderline.length == 3) {
        String category = orderline[0];
        String productName = orderline[1];
        String quantity = orderline[2];
        // Format the order details
        contentToPrint.writeln("$category\t\t$productName\t\t$quantity\n");
        print(
            "Orderline captured: Category: $category, Item: $productName, Quantity: $quantity");
      } else {
        print("Invalid order line format: $orderline");
      }
    }
    // Check for selected printer
    PrinterModel? selectedPrinter = await DatabaseHelper.instance
        .getPrinterByCategory(categoryId);

    if (selectedPrinter == null) {
      print("No printer found for category: $categoryId.");
      return;
    }
    print("Printer is selected: ${selectedPrinter.printerId}");
    print("Printer is selected: ${selectedPrinter.name}");

    try {
      // Check if the printer SDK's printer object is initialized
      //if (printer == null || !printer.getPrinterStatus(selectedPrinter.printerId)) {
      //  print("Printer is not initialized or not connected.");
      //  return;
      //}

      //print('printer status:   ');
      //print(printer.getPrinterStatus(selectedPrinter.printerId).toString());

      // Check if it's a receipt or a normal print task
      if (isitreceipt == false) {
        print("Order received for printing.");
        print('test' + contentToPrint.toString());

        await printer.printText(
          selectedPrinter.printerId,
          contentToPrinttitle.toString(),
          textWidthRatio: 0, // Adjust text size
          textHeightRatio: 0, // Adjust text size
          bold: true,
        );

        await printer.printText(
          selectedPrinter.printerId,
          contentToPrint.toString(),
          textWidthRatio: 0, // Adjust text size
          textHeightRatio: 0, // Adjust text size
          bold: false,
        );
        print('Printed to printer: ${selectedPrinter
            .name} for category ${categoryId} \n${contentToPrint.toString()}');
        await printer.printEscPosCommands(selectedPrinter.printerId,
            Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]));

        //if (contentToPrint.toString().contains('Order Completed')) {
        //  await printer.printEscPosCommands(selectedPrinter.printerId, Uint8List.fromList([0x1D, 0x56, 0x42, 0x00]));
        //}
      } else {
        print("Opening cash drawer for category: $categoryId");
        await printer.openCashDrawer(selectedPrinter.printerId);
        print('Cash drawer opened successfully.');
      }
    } catch (e) {
      print('Error during printing or cash drawer operation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e'))
      );
    }
  }



}

// Settings page with URL input and three buttons
class SettingsPage extends StatefulWidget {
  final Function(String) onUrlChanged; // Callback to update URL

  const SettingsPage({Key? key, required this.onUrlChanged}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _urlController = TextEditingController();
  final ClearDataHelper clearDataHelper = ClearDataHelper();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSTology',
      theme: AppTheme.appTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start, // Align content to the left
            crossAxisAlignment: CrossAxisAlignment.start, // Align to the top
          ),
        ),
        body: SingleChildScrollView( // Enable scrolling if content overflows
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height, // Set min height to the screen height
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Ensure content stays in the center
                crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the Row contents
                    children: [
                      Container(
                        width: 400, // Adjust this value as needed for desired width
                        child: TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter your company name',
                          ),
                          onSubmitted: (newUrl) {
                            _setUrlAndSwitch(newUrl); // Update the URL and switch to the portal
                          },
                        ),
                      ),
                      SizedBox(width: 10), // Add space between TextField and text
                      Text(
                        '.postology.cloud', // Text to display
                        style: TextStyle(
                          color: Colors.green, // Set text color
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                      SizedBox(width: 10), // Add space between text and button
                      ElevatedButton(
                        onPressed: () {
                          String url = _urlController.text.trim();
                          _setUrlAndSwitch(url); // Update the URL and switch to the portal
                        },
                        child: Text('Enter'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20), // Add space between rows
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the Column contents
                    children: [
                      Container(
                        width: 200, // Set width of the button
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => PrinterManagementPage()),
                            );
                          },
                          child: Text('Printers'),
                        ),
                      ),
                      SizedBox(height: 10), // Add space between buttons
                      Container(
                        width: 200, // Set width of the button
                        child: ElevatedButton(
                          onPressed: () {
                            // Uncomment and use once NearpayPaymentint page is available
                             Navigator.of(context).push(
                               MaterialPageRoute(builder: (context) => NearpayPaymentint()),
                            );
                          },
                          child: Text('Payment'),
                        ),
                      ),
                      SizedBox(height: 10), // Add space between buttons
                      Container(
                        width: 200, // Set width of the button
                        child: ElevatedButton(
                          onPressed: () {
                            _clearCookiesAndHistory(); // Clear cookies and history when pressed
                          },
                          child: Text('Rest'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  // New method to update URL, append postology.cloud, and switch to portal tab
  void _setUrlAndSwitch(String url) {
    if (url.isNotEmpty) {
      // Append "postology.cloud" to the URL
      String updatedUrl = 'https:://' + url + ".postology.cloud";
      widget.onUrlChanged(updatedUrl); // Update the URL
      // Switch to the portal tab
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage(selectedIndex: 0, initialUrl: updatedUrl)),
      );
    }
  }

  // Method to clear cookies and history
  void _clearCookiesAndHistory() async {
    await clearDataHelper.clearAllData();
    print('Cookies cleared.');
  }
}

