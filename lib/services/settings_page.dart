import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Function(String) onUrlChanged;

  const SettingsPage({Key? key, required this.onUrlChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController urlController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter URL:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://example.com',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String newUrl = urlController.text.trim();
                onUrlChanged(newUrl);
                Navigator.pop(context);
              },
              child: Text('Save URL'),
            ),
          ],
        ),
      ),
    );
  }
}
