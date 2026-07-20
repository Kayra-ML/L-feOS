import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'daily_screen.dart';
import 'life_screen.dart';
import 'second_brain_screen.dart';
import 'tasks_screen.dart';

/// Uygulamanın ana iskeleti: sol tarafta gizlenebilir sidebar (Drawer),
/// üstte her ekranda sabit duran Z-Asistan ve Takvim kısayolları.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _titles = ['Daily', 'Görevler', 'Life', 'Second Brain'];

  static const _screens = [
    DailyScreen(),
    TasksScreen(),
    LifeScreen(),
    SecondBrainScreen(),
  ];

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Takvim',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _openCalendar,
          ),
          IconButton(
            tooltip: 'Z-Asistan',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _openChat,
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onSelect: (i) => setState(() => _selectedIndex = i),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChat,
        tooltip: 'Z-Asistan ile sohbet et',
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}
