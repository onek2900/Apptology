/**

import 'package:flutter/material.dart';
import 'package:nearpay_flutter_sdk/nearpay.dart';


class NearpayPaymentint extends StatefulWidget {
  @override
  _NearpayPaymentintState createState() => _NearpayPaymentintState();
}

class _NearpayPaymentintState extends State<NearpayPaymentint> {
  String initializationStatus = "Not initialized";

  // Declare Nearpay as a class-level variable so that it can be accessed by both functions
  late Nearpay nearpay;

  // Method to initialize Nearpay
  Future<void> _initializeNearpay() async {
    nearpay = Nearpay(
      authType: AuthenticationType.login,
      authValue: " ",
      env: Environments.sandbox, // [Required] environment reference
      locale: Locale.localeDefault, // [Optional] locale reference
    );

    try {
      await nearpay.initialize();
      await nearpay.setup();
      setState(() {
        initializationStatus = "Initialization successful!";
      });
    } catch (e) {
      setState(() {
        initializationStatus = "Initialization failed: $e";
      });
    }
  }

  // Method to logout from Nearpay
  Future<void> _NearpayLogout() async {
    try {
      await nearpay.logout();
      setState(() {
        initializationStatus = "Logged out successfully!";
      });
    } catch (e) {
      setState(() {
        initializationStatus = "Logout failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearpay Payment Initialization'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              initializationStatus,
              style: TextStyle(fontSize: 20, color: Colors.green),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeNearpay, // Call the Nearpay initialization when pressed
              child: Text('Initialize Nearpay'),
            ),
            ElevatedButton(
              onPressed: _NearpayLogout, // Call Nearpay logout when pressed
              child: Text('Logout Nearpay'),
            ),
          ],
        ),
      ),
    );
  }
}
