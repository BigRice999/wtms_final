import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'submit_completion_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String workerId;
  const TaskListScreen({super.key, required this.workerId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // Fetch tasks assigned to the current worker from backend API.
  // Sends a POST request to the server with worker_id,
  // decodes the JSON response, and updates the UI with task list.
  Future<void> _fetchTasks() async {
    try {
      // print outgoing request for debugging
      debugPrint("📤 Sending request with worker_id: ${widget.workerId}");

      // send POST request to backend PHP API
      final response = await http.post(
        Uri.parse("http://10.0.2.2/wtms_api/get_works.php"),
        body: {'worker_id': widget.workerId},
      );

      // print response details for troubleshooting
      debugPrint("📥 Response code: ${response.statusCode}");
      debugPrint("📦 Response body: ${response.body}");

      // decode Json and map to Task object if requested successfully
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        debugPrint("✅ Decoded JSON: $data");

        setState(() {
          _tasks = data.map((e) => Task.fromJson(e)).toList();
          _loading = false;
        });

      } else {
        throw Exception('Failed to load tasks');
      }

    } catch (e) {
      setState(() => _loading = false);
      debugPrint("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading tasks: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(
          "My Assigned Tasks",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 179, 127, 6),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 237, 149),
        elevation: 0,
      ),

      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30), // global padding like other screens
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 249, 188), Colors.white],
            begin: Alignment.topCenter,
          ),
        ),

        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
                ? const Center(child: Text("No tasks assigned."))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];

                      return Container( // Display assigned task
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color.fromARGB(255, 255, 204, 1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text( // Task Title
                              task.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),
                            Text( // Task Description
                              task.description,
                              style: const TextStyle(fontSize: 15),
                            ),

                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 255, 242, 197),
                                  ),

                                  child: Text(
                                    "Due: ${task.dueDate}",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                Text(
                                  "Status: ${task.status}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 255, 204, 0),
                                  foregroundColor: Colors.black,
                                ),
                                
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubmitCompletionScreen(task: task),
                                    ),
                                  );
                                },
                                child: const Text("SUBMIT COMPLETION"),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
