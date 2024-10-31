import 'package:flutter/material.dart';
import 'package:postology/theme/app_theme.dart';
import 'package:postology/my_intro_page.dart'; // Import your MyIntroPage widget
import 'package:postology/my_home_page.dart'; // Import your MyHomePage widget
import 'package:postology/settings_page.dart'; // Import your SettingsPage widget

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSTology',
      theme: AppTheme.appTheme,
      home: IntroPage(), // Display intro page initially, or MyHomePage if desired
    );
  }
}
