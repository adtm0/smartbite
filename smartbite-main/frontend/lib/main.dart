import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'sign_up_screen.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'forget_password.dart';
import 'main_screen_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBite',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black, // Used for general primary elements
        cardColor: Colors.grey[200], // Lighter card color for light mode for contrast
        iconTheme: const IconThemeData(color: Colors.black87), // Slightly softer black
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87), // Add bodyMedium if used
          labelLarge: TextStyle(fontSize: 16, color: Colors.black), // For button text, etc.
        ),
        // Add other properties like appBarTheme, buttonTheme if needed
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black, // Default icon/text color in app bar
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white, // Used for general primary elements
        cardColor: Colors.grey[850], // Darker card color for dark mode for contrast
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white), // Add bodyMedium if used
          labelLarge: TextStyle(fontSize: 16, color: Colors.white), // For button text, etc.
        ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white, // Default icon/text color in app bar
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(),
        '/main': (context) => MainScreenWrapper(onToggleTheme: _toggleTheme),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}