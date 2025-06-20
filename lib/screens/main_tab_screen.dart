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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return TaskListScreen(workerId: widget.worker.id);
      case 1:
        return SubmissionHistoryScreen(workerId: widget.worker.id);
      case 2:
        return ProfileScreen(worker: widget.worker);
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("MainTabScreen: currentIndex = $_currentIndex");

    return Scaffold(
      body: _buildBody(),
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
