import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:postology/printer_management.dart';
import 'package:postology/nearpay_paymentint.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'package:sunmi_printerx/sunmi_printerx_method_channel.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';

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
          // Initialize variables for storing printer data and order information
          String printername = "";
          List<String> consoleLogs = [];

          // Check if the message is an order start
          if (consoleMessage.message.contains("Order Start")) {
            print("Order received");
          }

          // Check if the message contains printer information
          if (consoleMessage.message.contains("Printer:")) {
            printername = consoleMessage.message.split("Printer:")[1].trim();
            print("Printer identified: $printername");
          }

          // Extract and store other order details
          if (consoleMessage.message.contains("Cashier:") ||
              consoleMessage.message.contains("Order Number:") ||
              consoleMessage.message.contains("\t")) {
            consoleLogs.add(consoleMessage.message);
          }

          // Once "Order Completed" is received, trigger the print function
          if (consoleMessage.message.contains("Order Completed")) {
            if (printername.isNotEmpty) {
              _printToMainPrinter(false, printername, consoleLogs);  // Call the print function with the collected logs
            } else {
              print("No printer found for the order.");
            }

            // Clear variables after processing
            printername = '';
            consoleLogs = [];
          }

          // Handle print_completed message
          if (consoleMessage.message.contains("postology:print_completed")) {
            _printToMainPrinter(true, 'main', []); // Just opening the cash drawer
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

  Future<void> _printToMainPrinter(bool isitreceipt, String categoryId, List<String> consoleLogs) async {
    // Prepare a buffer for the content to be printed
    StringBuffer contentToPrint = StringBuffer();

    // Iterate over the console logs and format them accordingly
    for (String log in consoleLogs) {
      // Skip the "Order Start" and "Order Completed" messages
      if (log.contains('Order Start') || log.contains('Order Completed')) {
        continue;
      }
      // Add the relevant data to the buffer
      contentToPrint.writeln(log);
      print("data captured :  ");

    }
    PrinterModel? selectedPrinter = await DatabaseHelper.instance.getPrinterByCategory(categoryId);
    // Check if it's a receipt or a normal print task
    if (isitreceipt==false) {
      print("order recieved");
      if (selectedPrinter != null) {
        print("printer is selected");
        try {
          await printer.printText(
            selectedPrinter.printerId,
            contentToPrint.toString(),
            textWidthRatio: 1, // Adjust text size
            textHeightRatio: 1, // Adjust text size
            bold: true,
          );
          print('Printed to printer: ${selectedPrinter.name} for category ${categoryId} \n${contentToPrint.toString()}');
        } catch (e) {
          print('Error printing to category printer: $e');
        }
      } else {
        print('No printer found for category: $categoryId.');
      }
    } else {
      if (selectedPrinter != null) {
        print("printer is selected");
        try {
          print('drawer open to: $categoryId');
          await printer.openCashDrawer(selectedPrinter.printerId);
          print('Cash drawer opened successfully.');
          print('Printed to printer: ${selectedPrinter.name} for category ${categoryId} \n${contentToPrint.toString()}');
        } catch (e) {
          print('Error opening cash drawer: $e');
        }
      }
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
        body:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the Row contents
                children: [
                  // Set the width of the TextField to fit approximately 20 characters
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
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center the Column contents
                children: [
                  Container(
                    width: 200, // Set width of the button
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to PrinterManagementPage when the button is pressed
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
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => NearpayPaymentint()), // Navigate to NearpayPage
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
    await CookieManager.instance().deleteAllCookies(); // Clear all cookies
    print('Cookies cleared.');
  }
}
