import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Web view for the portal
import 'package:postology/printer_management.dart';
import 'package:postology/nearpay_paymentint.dart';
import 'package:sunmi_printerx/sunmi_printerx.dart';
import 'models/printer_model.dart';
import 'database/database_helper.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSTology',
      theme: ThemeData(
        brightness: Brightness.dark, // Set to dark theme
        primaryColor: Colors.green, // Primary color for app elements
        colorScheme: ColorScheme.dark(primary: Colors.green), // Use ColorScheme for the dark theme
        scaffoldBackgroundColor: Colors.grey[900], // Dark gray background color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800], // AppBar background color
          titleTextStyle: TextStyle(color: Colors.green, fontSize: 20), // AppBar title text style
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.green, // Button background color
          textTheme: ButtonTextTheme.primary, // Button text color
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white), // Use displayLarge for main text
          displayMedium: TextStyle(color: Colors.white), // Use displayMedium for secondary text
          bodyLarge: TextStyle(color: Colors.white), // Use bodyLarge for regular text
          bodyMedium: TextStyle(color: Colors.white), // Use bodyMedium for regular text
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800], // Input field background color
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green), // Input field border color
          ),
          labelStyle: TextStyle(color: Colors.green), // Label text color
          hintStyle: TextStyle(color: Colors.grey[400]), // Hint text color
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          // Align content to the left
          crossAxisAlignment: CrossAxisAlignment.start,
          // Align to the top
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              // Add a single line space from the top
              child: Image.asset(
                'assets/POSTology.png', // Path to the image
                width: 50.0, // Set width for the logo
                height: 50.0, // Set height for the logo
              ),
            ),
          ],
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
          onConsoleMessage: (controller, consoleMessage) {
          print("Console message: ${consoleMessage.message}");
          // Assuming you want to print the message
          _printToMainPrinter(consoleMessage.message); // Pass the message as content to print
          },

        onLoadStop: (controller, url) async {
          print("Finished loading: $url");

          // Inject JavaScript to trigger print request with content
          controller.evaluateJavascript(source: '''
            window.print = function() {
              var contentToPrint = document.body.innerText || document.body.textContent; // Customize this to get the actual content to print
              console.log("print_request:" + contentToPrint); // Send the content to the console for Flutter to capture
            };
          ''');
        },
      ),
    );
  }

  Future<void> _printToMainPrinter(String contentToPrint) async {
    PrinterModel? mainPrinter = await DatabaseHelper.instance.getMainPrinter();

    if (mainPrinter != null) {
      // Print on the main printer using the printerId and the content
      try {
        await printer.printText(
          mainPrinter.printerId, // Pass the printerId here
          contentToPrint, // Pass the content to print
          textWidthRatio: 1, // Optional: You can adjust text width ratio
          textHeightRatio: 1, // Optional: You can adjust text height ratio
          bold: true, // Optional: If you want bold text
        );
        //await printer.openCashDrawer(); // Optional: Open the cash drawer after printing
        print('Printed to main printer: ${mainPrinter.name}');
      } catch (e) {
        print('Error printing to main printer: $e');
      }
    } else {
      print('No main printer set in the database.');
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
      theme: ThemeData(
        brightness: Brightness.dark, // Set to dark theme
        primaryColor: Colors.green, // Primary color for app elements
        colorScheme: ColorScheme.dark(primary: Colors.green), // Use ColorScheme for the dark theme
        scaffoldBackgroundColor: Colors.grey[900], // Dark gray background color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800], // AppBar background color
          titleTextStyle: TextStyle(color: Colors.green, fontSize: 20), // AppBar title text style
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.green, // Button background color
          textTheme: ButtonTextTheme.primary, // Button text color
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white), // Use displayLarge for main text
          displayMedium: TextStyle(color: Colors.white), // Use displayMedium for secondary text
          bodyLarge: TextStyle(color: Colors.white), // Use bodyLarge for regular text
          bodyMedium: TextStyle(color: Colors.white), // Use bodyMedium for regular text
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800], // Input field background color
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green), // Input field border color
          ),
          labelStyle: TextStyle(color: Colors.green), // Label text color
          hintStyle: TextStyle(color: Colors.grey[400]), // Hint text color
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start, // Align content to the left
            crossAxisAlignment: CrossAxisAlignment.start, // Align to the top
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0), // Add a single line space from the top
                child: Image.asset(
                  'assets/POSTology.png', // Path to the image
                  width: 50.0, // Set width for the logo
                  height: 50.0, // Set height for the logo
                ),
              ),
            ],
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
