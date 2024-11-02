import 'package:flutter/material.dart';
import 'package:postology/my_intro_page.dart';
import 'package:postology/my_home_page.dart';
import 'package:postology/theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Postology App',
      theme: AppTheme.appTheme, // Use your custom app theme from AppTheme
      initialRoute: '/intro', // Initial route set to intro page
      routes: {
        '/intro': (context) => MyIntroPage(),
      },
    );
  }
}
