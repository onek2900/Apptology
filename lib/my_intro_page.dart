import 'package:flutter/material.dart';
import 'package:apptology/theme/app_theme.dart';
import 'package:apptology/my_home_page.dart'; // Adjust import based on your file structure
import 'package:apptology/printer_management.dart';
import 'package:apptology/nearpay_paymentint.dart';
import 'package:apptology/models/ClearHelper.dart';


class MyIntroPage extends StatefulWidget {
  @override
  _MyIntroPageState createState() => _MyIntroPageState();
}

class _MyIntroPageState extends State<MyIntroPage> {
  TextEditingController _textEditingController = TextEditingController();
  final ClearDataHelper clearDataHelper = ClearDataHelper();



  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appTheme.scaffoldBackgroundColor,
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                SizedBox(width: 30),
                Center(
                  child: Image.asset(
                    'assets/postology_logoL.png',
                    width: 45,
                    height: 70,
                    alignment: Alignment.topCenter,
                  ),
                ),
                SizedBox(width: 10),
                Center(
                  child: Image.asset(
                    'assets/Apptology_logo.png',
                    width: 550,
                    height: 80,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20.0), // Adjust padding as needed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              labelText: 'Enter your company name',
                              hintText: '.postology.cloud',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green),
                              ),
                            ),
                            onChanged: (value) {
                              // Automatically add '.postology.cloud' while typing
                              if (!_textEditingController.text.endsWith(
                                  '.postology.cloud')) {
                                _textEditingController.value = TextEditingValue(
                                  text: value.endsWith('.postology.cloud')
                                      ? value
                                      : '$value.postology.cloud',
                                  selection: TextSelection.collapsed(
                                      offset: _textEditingController.text
                                          .length),
                                );
                              }
                            },
                            onSubmitted: (value) {
                              String enteredUrl = _textEditingController.text
                                  .trim();
                              String updatedUrl = 'https://$enteredUrl'; // Get the entered URL
                              if (enteredUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      MyHomePage(url: updatedUrl)),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        // Optional spacing between TextField and ElevatedButton
                        SizedBox(
                          width: 100, // Fixed width for the ElevatedButton
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to MyHomePage with the URL from the text field
                              String enteredUrl = _textEditingController.text
                                  .trim();
                              String updatedUrl = 'https://$enteredUrl'; // Construct the URL
                              if (enteredUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      MyHomePage(url: updatedUrl)),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0), // Adjust vertical padding as needed
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Adjust border radius as needed
                              ),
                              backgroundColor: Color(0xFFC2DA69),
                            ),
                            child: Text('Start'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  Container(
                    alignment: Alignment.bottomCenter,
                    // Aligns the content at the bottom center of the container
                    padding: EdgeInsets.all(16.0),
                    // Optional padding around the row of buttons
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,

                      // Adjust as needed
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) =>
                                    PrinterManagementPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0), // Adjust vertical padding as needed
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Adjust border radius as needed
                              ),
                              backgroundColor: Color(0xFFC2DA69),
                            ),
                            child: Text('Printer'),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              // Uncomment and use once NearpayPaymentint page is available
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => NearpayPaymentint()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0), // Adjust vertical padding as needed
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Adjust border radius as needed
                              ),
                              backgroundColor: Color(0xFFC2DA69),
                            ),
                            child: Text('Payment'),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              _clearCookiesAndHistory(); // Clear cookies and history when pressed
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0), // Adjust vertical padding as needed
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Adjust border radius as needed
                              ),
                              backgroundColor: Color(0xFFC2DA69),
                            ),
                            child: Text('Rest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    // Method to clear cookies and history
  void _clearCookiesAndHistory() async {
    await clearDataHelper.clearAllData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Settings are cleared.")),
    );
    print('Cookies cleared.');
  }
}
