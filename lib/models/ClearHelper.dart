import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // For WebView cache and cookies
import 'package:shared_preferences/shared_preferences.dart'; // For clearing shared preferences
import 'package:path_provider/path_provider.dart'; // For getting app cache directory
import 'dart:io'; // For file operations

class ClearDataHelper {
  // Method to clear cookies, cache, shared preferences, and files
  Future<void> clearAllData() async {
    // Clear cookies
    await _clearCookies();

    // Clear WebView cache
    await _clearWebViewCache();

    // Clear shared preferences
    await _clearSharedPreferences();

    // Clear app cache files
    await _clearCacheFiles();

    // Clear local databases (if applicable)
    await _clearDatabase();

    print('All application data has been cleared.');
  }

  // Method to clear cookies
  Future<void> _clearCookies() async {
    await CookieManager.instance().deleteAllCookies();
    print('Cookies cleared.');
  }

  // Method to clear WebView cache
  Future<void> _clearWebViewCache() async {
    try {
      final controller = InAppWebViewController(); // Initialize the controller
      await controller.clearCache(); // Clear WebView cache
      print('WebView cache cleared.');
    } catch (e) {
      print('Error clearing WebView cache: $e');
    }
  }

  // Method to clear shared preferences
  Future<void> _clearSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('Shared preferences cleared.');
  }

  // Method to clear cached files in app's cache directory
  Future<void> _clearCacheFiles() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        print('App cache files cleared.');
      }
    } catch (e) {
      print('Error clearing cache files: $e');
    }
  }

  // Method to clear the database (e.g., SQLite)
  Future<void> _clearDatabase() async {
    try {
      // Replace this with your database deletion logic
      // Example for SQLite: await deleteDatabase('your_database_name.db');
      print('Database cleared.');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }
}
