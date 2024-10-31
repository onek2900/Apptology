import 'package:flutter/material.dart';

class AppTheme {
  // Define your primary color and other theme settings here
  static final ThemeData appTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green,
    colorScheme: ColorScheme.light(primary: Colors.green),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.green, fontSize: 20),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.green,
      textTheme: ButtonTextTheme.primary,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.green), // Example of bodyText1 usage
      bodyMedium: TextStyle(color: Colors.green), // Example of bodyText2 usage
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
      ),
      labelStyle: TextStyle(color: Colors.green),
      hintStyle: TextStyle(color: Colors.grey[400]),
    ),
  );

  // Define introTitleStyle and introSubtitleStyle here
  static final TextStyle introTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

  static final TextStyle introSubtitleStyle = TextStyle(
    fontSize: 18,
    color: Colors.green,
  );
}
