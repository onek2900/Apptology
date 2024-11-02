import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData appTheme = ThemeData(
    brightness: Brightness.light, // Set to light theme
    primaryColor: Color(0xFFC2DA69), // Primary color for app elements
    colorScheme: ColorScheme.light(primary: Color(0xFF222222)), // Use ColorScheme for the light theme
    scaffoldBackgroundColor: Colors.white, // White background color
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white, // AppBar background color
      elevation: 0, // Remove elevation
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFFC2DA69), // Button background color
      textTheme: ButtonTextTheme.primary, // Button text color
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Color(0xFFC2DA69)), // Use headline6 for main text
      bodyMedium: TextStyle(color: Color(0xFFC2DA69)), // Use bodyText2 for regular text
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Input field background color
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFC2DA69)), // Input field border color
      ),
      labelStyle: TextStyle(color: Color(0xFFC2DA69)), // Label text color
      hintStyle: TextStyle(color: Colors.grey[400]), // Hint text color
    ),
  );
}
