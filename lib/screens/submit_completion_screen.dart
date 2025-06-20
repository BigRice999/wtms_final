import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class SubmitCompletionScreen extends StatefulWidget {
  final Task task;

  const SubmitCompletionScreen({super.key, required this.task});

  @override
  State<SubmitCompletionScreen> createState() => _SubmitCompletionScreenState();
}

class _SubmitCompletionScreenState extends State<SubmitCompletionScreen> {
  final TextEditingController _submissionController = TextEditingController();
  bool _submitting = false;

  Future<void> _submitWork() async {
    String submissionText = _submissionController.text;

    if (submissionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter submission details")),
      );
      return;
    }

    setState(() => _submitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workerId = prefs.getString('worker_id');

    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker ID not found.")),
      );
      setState(() => _submitting = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("http://10.0.2.2/wtms_api/submit_work.php"),
        body: {
          'worker_id': workerId,
          'work_id': widget.task.id,
          'submission_text': submissionText,
        },
      );

      setState(() => _submitting = false);

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Submission successful!")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server error during submission")),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection lost. Please try again.")),
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
          "Submit Task Completion",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 153, 120, 0),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 236, 137),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 100, 30, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 249, 188), Colors.white],
            begin: Alignment.topCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color.fromARGB(255, 255, 214, 80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Task Title:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.task.title,
                    style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 16),
                Text("Work ID: ${widget.task.id}",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),

                const SizedBox(height: 40),
                const Text("What did you complete?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: _submissionController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: "Enter your completion details here",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 30),
                _submitting
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitWork,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 204, 0),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text("Submit"),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
