import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData appTheme = ThemeData(
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
  );
}
