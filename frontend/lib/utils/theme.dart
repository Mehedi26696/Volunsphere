import 'package:flutter/material.dart';

// Primary green color you want
const primaryGreen = Color(0xFF008000); // pure green or use your custom green

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryGreen,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white, // Text color on AppBar
  ),
  colorScheme: ColorScheme.light(
    primary: primaryGreen,
    secondary: Colors.green.shade700,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(primaryGreen),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryGreen,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.dark(
    primary: primaryGreen,
    secondary: Colors.green.shade300,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white60),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.black,
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(primaryGreen),
  ),
);
