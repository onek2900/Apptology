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
          // Listen to messages sent from the web page console (e.g., print command)
          print("Console message: ${consoleMessage.message}");

          // Check if the message contains the print request
          if (consoleMessage.message.contains("postology:print_completed"))
            {
            final contentToPrint = consoleMessage.message.split("postology:print_completed")[1].trim();
             bool isitreceipt = true;
            _printToMainPrinter(isitreceipt, contentToPrint); // Pass the content to print
          }

          if (consoleMessage.message.contains("order_request:"))
                {
                  final contentToPrint = consoleMessage.message.split("order_request:")[1].trim();
                  bool isitreceipt = false;
                  _printToMainPrinter(isitreceipt, contentToPrint); // Pass the content to print
          }
        },
        onLoadStop: (controller, url) async {
          // Inject JavaScript to add a `beforeprint` listener that captures the content and sends a console log
          await controller.evaluateJavascript(source: '''
          if (!window.printListenerAdded) {
            window.addEventListener('beforeprint', function() {
              var contentToPrint = document.body.innerText || document.body.textContent;
                    console.log("order_request:" + contentToPrint);  // Send the content to Flutter
            });
             window.printListenerAdded = true;  // Ensure this listener is added only once
          }
          ''');

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

  Future<void> _printToMainPrinter(bool isitreceipt, String contentToPrint) async {
    print("_printToMainPrinter " +  isitreceipt.toString()  + contentToPrint);
    if (isitreceipt == true) {
      PrinterModel? mainPrinter = await DatabaseHelper.instance.getMainPrinter();
      print("_printToMainPrinter - TRY " + isitreceipt.toString() + (mainPrinter?.printerId ?? 'Unknown'));
      if (mainPrinter != null) {
        // Print on the main printer using the printerId and the content
        try {
          bool drawerOpened = await printer.openCashDrawer(mainPrinter.printerId);
          if (drawerOpened) {
            print('Cash drawer opened successfully for: ${mainPrinter.name}');
          } else {
            print('Failed to open cash drawer for: ${mainPrinter.name}');
          }
          print('Printed to main printer: ${mainPrinter.name}');
        } catch (e) {
          print('Error printing to main printer: $e');
        }
      } else {
        print('No main printer set in the database.');
      }
    } else {
      PrinterModel? secPrinter = await DatabaseHelper.instance.getSecPrinter();
      print("_printToMainPrinter - TRY Sec " + isitreceipt.toString() + (secPrinter?.printerId ?? 'Unknown'));
      if (secPrinter != null) {
        try {
          await printer.printText(
            secPrinter.printerId,
            contentToPrint,
            textWidthRatio: 1,
            textHeightRatio: 1,
            bold: true,
          );
          print('Printed to secondary printer: ${secPrinter.name} \n'
              '${contentToPrint}');

        } catch (e) {
          print('Error printing to secondary printer: $e');
        }
      } else {
        print('No secondary printer set in the database.');
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
