// lib/main_screen_wrapper.dart

import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'diaryscreen.dart';
import 'settings_screen.dart';

class MainScreenWrapper extends StatefulWidget {
  final void Function()? onToggleTheme;

  MainScreenWrapper({super.key, this.onToggleTheme});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> _widgetOptions = <Widget>[
      MainScreen(),
      DiaryScreen(onToggleTheme: widget.onToggleTheme),
      SettingsScreen(onToggleTheme: widget.onToggleTheme),
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: theme.iconTheme.color?.withOpacity(0.6),
        backgroundColor: theme.cardColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 