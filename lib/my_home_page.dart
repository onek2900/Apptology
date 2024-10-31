import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:postology/settings_page.dart'; // Assuming SettingsPage import

class MyHomePage extends StatefulWidget {
  final String initialUrl;

  MyHomePage({Key? key, required this.initialUrl}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _webViewController.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri('https://apptolgoyinc.com'), // Use WebUri.parse for loading URLs
                    ),
                  );
                },
                child: Text('POS'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage(
                      onUrlChanged: (String newUrl) {
                        // Handle URL change logic here if needed
                      },
                    )),
                  );
                },
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
