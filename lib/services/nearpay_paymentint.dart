import 'package:flutter/material.dart';
import 'nearpay_service.dart'; // Import your service file

class NearpayPaymentint extends StatefulWidget {
  @override
  _NearpayPaymentintState createState() => _NearpayPaymentintState();
}

class _NearpayPaymentintState extends State<NearpayPaymentint> {
  String initializationStatus = "Not initialized";
  final NearpayService nearpayService = NearpayService(); // Create an instance of your service class

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
              onPressed: () async {
                try {
                  await nearpayService.initializeNearpay();
                  setState(() {
                    initializationStatus = "Initialization successful!";
                  });
                } catch (e) {
                  setState(() {
                    initializationStatus = "Initialization failed: $e";
                  });
                }
              },
              child: Text('Initialize Nearpay'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await nearpayService.logoutNearpay();
                  setState(() {
                    initializationStatus = "Logged out successfully!";
                  });
                } catch (e) {
                  setState(() {
                    initializationStatus = "Logout failed: $e";
                  });
                }
              },
              child: Text('Logout Nearpay'),
            ),
          ],
        ),
      ),
    );
  }
}
