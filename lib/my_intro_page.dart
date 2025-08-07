import 'package:flutter/material.dart';
import 'package:apptology/theme/app_theme.dart';
import 'package:apptology/my_home_page.dart';
import 'package:apptology/services/printer_management.dart';
import 'package:apptology/services/nearpay_paymentint.dart';
import 'package:apptology/models/ClearHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyIntroPage extends StatefulWidget {
  @override
  _MyIntroPageState createState() => _MyIntroPageState();
}

class _MyIntroPageState extends State<MyIntroPage> with AutomaticKeepAliveClientMixin {
  TextEditingController _textEditingController = TextEditingController();
  final ClearDataHelper clearDataHelper = ClearDataHelper();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _loadSavedCompanyName();
  }
  Future<void> _loadSavedCompanyName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('company_name');
    if (savedName != null) {
      setState(() {
        _textEditingController.text = savedName;
      });
    }
  }

  Future<void> _saveCompanyName(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure to call super.build(context) in your build method
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
              padding: const EdgeInsets.all(20.0),
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
                            key: PageStorageKey('companyNameTextField'), // Assign PageStorageKey to TextField
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              labelText: 'Enter your company name',
                              hintText: '.postology.cloud',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green),
                              ),
                            ),
                            onChanged: (value) {
                              if (!_textEditingController.text.endsWith('.postology.cloud')) {
                                _textEditingController.value = TextEditingValue(
                                  text: value.endsWith('.postology.cloud')
                                      ? value
                                      : '$value.postology.cloud',
                                  selection: TextSelection.collapsed(offset: _textEditingController.text.length),
                                );
                              }
                            },
                            onSubmitted: (value) {
                              String enteredUrl = _textEditingController.text.trim();
                              String updatedUrl = 'https://$enteredUrl';
                              if (enteredUrl.isNotEmpty) {
                                _saveCompanyName(value); // Save on submit
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyHomePage(url: updatedUrl)),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () async {
                              String enteredUrl = _textEditingController.text.trim();
                              String updatedUrl = 'https://$enteredUrl';
                              if (enteredUrl.isNotEmpty) {
                                await _saveCompanyName(enteredUrl); // Save the value
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyHomePage(url: updatedUrl)),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
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
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => PrinterManagementPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
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
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => NearpayPaymentint()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
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
                              _clearCookiesAndHistory();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
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

  void _clearCookiesAndHistory() async {
    await clearDataHelper.clearAllData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Settings are cleared.")),
    );
    print('Cookies cleared.');
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
