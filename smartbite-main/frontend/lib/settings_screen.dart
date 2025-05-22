// lib/settings_screen.dart

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  // This will be the simple toggle function coming from MainScreenWrapper (and ultimately main.dart)
  final VoidCallback? onToggleTheme;

  const SettingsScreen({
    super.key,
    this.onToggleTheme, // Now accepts a simple VoidCallback
  });

  // Helper to get the current theme mode string for display
  String _getThemeModeString(BuildContext context) {
    // This is a simple way to check the current brightness to show "Light" or "Dark"
    // It doesn't know "Default" (system) because it only sees the resolved brightness.
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? 'Light' : 'Dark';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Appearance',
                      style: TextStyle(color: textColor),
                    ),
                    trailing: Switch(
                      value: theme.brightness == Brightness.dark,
                      onChanged: (bool value) {
                        onToggleTheme?.call();
                      },
                    ),
                    onTap: () {
                      // Trigger the theme toggle that comes from main.dart
                      onToggleTheme?.call();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 