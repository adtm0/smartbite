// lib/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_service.dart';
import 'dart:convert';

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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  List<String> _parseErrorMessages(String errorText) {
    try {
      final decoded = json.decode(errorText);
      if (decoded is Map) {
        return decoded.values.expand((v) => v is List ? v : [v.toString()]).map((e) => e.toString()).toList();
      }
      return [errorText];
    } catch (_) {
      return [errorText];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Colors.black,
          ),
          textAlign: TextAlign.left,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                  width: 360,
              decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
              ),
              child: Column(
                children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        onTap: onToggleTheme,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              const Text(
                      'Appearance',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              Spacer(),
                              Text(
                                'Default',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Color(0xFF26C85A),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1, thickness: 1),
                      InkWell(
                        borderRadius: BorderRadius.zero,
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              final currentController = TextEditingController();
                              final newController = TextEditingController();
                              final reenterController = TextEditingController();
                              final formKey = GlobalKey<FormState>();
                              String? errorText;
                              bool isLoading = false;
                              return StatefulBuilder(
                                builder: (context, setState) => Dialog(
                                  backgroundColor: const Color(0xFF232323),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                    child: Form(
                                      key: formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Change Password',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          TextFormField(
                                            controller: currentController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'Current Password',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                            validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: newController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'New Password',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: reenterController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'Reenter Password',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                            validator: (v) => v != newController.text ? 'Passwords do not match' : null,
                                          ),
                                          if (errorText != null) ...[
                                            const SizedBox(height: 10),
                                            ..._parseErrorMessages(errorText!).map((msg) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('• ', style: TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13)),
                                                  Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13))),
                                                ],
                                              ),
                                            )),
                                          ],
                                          const SizedBox(height: 18),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                                ),
                                                onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      if (!formKey.currentState!.validate()) return;
                                                      setState(() { isLoading = true; errorText = null; });
                                                      try {
                                                        await UserService.changePassword(
                                                          currentPassword: currentController.text,
                                                          newPassword: newController.text,
                                                          reNewPassword: reenterController.text,
                                                        );
                                                        if (context.mounted) {
                                                          Navigator.of(context).pop();
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Password changed successfully!')),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        setState(() { errorText = e.toString().replaceFirst('Exception: ', ''); });
                                                      } finally {
                                                        setState(() { isLoading = false; });
                                                      }
                                                    },
                                                child: isLoading
                                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Text(
                                                      'Save',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1, thickness: 1),
                      InkWell(
                        borderRadius: BorderRadius.zero,
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              final confirmController = TextEditingController();
                              final passwordController = TextEditingController();
                              final formKey = GlobalKey<FormState>();
                              String? errorText;
                              bool isLoading = false;
                              return StatefulBuilder(
                                builder: (context, setState) => Dialog(
                                  backgroundColor: const Color(0xFF232323),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                    child: Form(
                                      key: formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Delete Account',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            "We're sad to see you go. So you're aware, deleting your account will permanently remove your account and all progress. You cannot undo this action.\n\nEnter the word Confirm and your password to perform this action.",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: confirmController,
                                            decoration: InputDecoration(
                                              hintText: 'Type Confirm',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                            validator: (v) => v?.trim() != 'Confirm' ? 'Type Confirm to proceed' : null,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: passwordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'Current Password',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            ),
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                                          ),
                                          if (errorText != null) ...[
                                            const SizedBox(height: 10),
                                            ..._parseErrorMessages(errorText!).map((msg) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('• ', style: TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13)),
                                                  Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13))),
                                                ],
                                              ),
                                            )),
                                          ],
                                          const SizedBox(height: 18),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                                ),
                                                onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      if (!formKey.currentState!.validate()) return;
                                                      setState(() { isLoading = true; errorText = null; });
                                                      try {
                                                        await UserService.deleteAccount(
                                                          currentPassword: passwordController.text,
                                                        );
                                                        if (context.mounted) {
                                                          Navigator.of(context).pop();
                                                          final prefs = await SharedPreferences.getInstance();
                                                          await prefs.remove('auth_token');
                                                          if (context.mounted) {
                                                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Account deleted successfully.')),
                                                            );
                                                          }
                                                        }
                                                      } catch (e) {
                                                        setState(() { errorText = e.toString().replaceFirst('Exception: ', ''); });
                                                      } finally {
                                                        setState(() { isLoading = false; });
                                                      }
                                                    },
                                                child: isLoading
                                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1, thickness: 1),
                      InkWell(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        onTap: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: SizedBox(
                                width: 273,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Log Out',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          height: 22 / 20,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 10),
                                      const Text(
                                        'Are you sure you want to log out?',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13,
                                          height: 22 / 13,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text(
                                              'No',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 13,
                                                height: 22 / 13,
                                                letterSpacing: 0,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(width: 32),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Yes',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 13,
                                                height: 22 / 13,
                                                letterSpacing: 0,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          if (shouldLogout == true) {
                            await _logout(context);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 