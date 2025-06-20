import 'package:flutter/material.dart';
import 'package:wtms/models/worker.dart';
import 'package:wtms/screens/profile_screen.dart';
import 'package:wtms/screens/submission_history_screen.dart';
import 'package:wtms/screens/task_list_screen.dart';

class MainTabScreen extends StatefulWidget {
  final Worker worker;

  const MainTabScreen({super.key, required this.worker});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TaskListScreen(workerId: widget.worker.id),
      SubmissionHistoryScreen(workerId: widget.worker.id),
      ProfileScreen(worker: widget.worker),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color.fromARGB(255, 255, 145, 0),
        unselectedItemColor: const Color.fromARGB(255, 134, 190, 185),
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
