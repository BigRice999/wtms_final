import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubmissionHistoryScreen extends StatefulWidget {
  final String workerId;

  const SubmissionHistoryScreen({super.key, required this.workerId});

  @override
  State<SubmissionHistoryScreen> createState() => _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  List submissions = [];
  bool isLoading = true;
  bool sortLatestFirst = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🔁 SubmissionHistoryScreen initState called");
    isLoading = true;
    submissions = [];
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2/wtms_api/get_submissions.php"),
      body: {"worker_id": widget.workerId},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        List result = data['data'];
        setState(() {
          submissions = sortLatestFirst ? result.reversed.toList() : result;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "No submissions found.")),
        );
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load submissions")),
      );
    }
  }

  void _showEditPopup(Map item) {
    final TextEditingController controller = TextEditingController(text: item['submission_text']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromARGB(255, 64, 187, 167)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You are only allowed to edit Completion Details."))),
                child: Text(
                  item['title'] ?? '',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You are only allowed to edit Completion Details."))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(221, 89, 80, 72),
                  ),
                  child: Text(
                    "Submitted at ${item['submitted_at']}",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 255, 221),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Edit your submission here",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  child: const Text("SAVE"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showConfirmDialog(item['id'].toString(), controller.text);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(String submissionId, String updatedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Are you sure you want to update the completion details?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("NO"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _submitEdit(submissionId, updatedText);
            },
            child: const Text("YES"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEdit(String submissionId, String updatedText) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2/wtms_api/edit_submission.php"),
      body: {
        "submission_id": submissionId,
        "updated_text": updatedText,
      },
    );

    final result = json.decode(response.body);
    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
      fetchSubmissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update')),
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
          "Submission History",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 7, 162, 115),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 159, 232, 205),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.teal),
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                sortLatestFirst = !sortLatestFirst;
                submissions = submissions.reversed.toList();
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 159, 232, 205), Colors.white],
            begin: Alignment.topCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : submissions.isEmpty
                ? const Center(child: Text("No submissions found."))
                : ListView.builder(
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      var item = submissions[index];
                      final id = item['id'].toString();
                      final title = item['title'] ?? 'No Title';
                      final date = item['submitted_at'] ?? 'Unknown Date';
                      final text = item['submission_text'] ?? '';
                      final preview = text.length > 30 ? text.substring(0, 30) + '...' : text;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20), 
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color.fromARGB(255, 64, 187, 167)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showEditPopup(item),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 155, 226, 217),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.edit, color: Color.fromARGB(255, 115, 107, 88), size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Submission ID: $id",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(221, 89, 80, 72),
                              ),
                              child: Text(
                                "Submitted at $date",
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 255, 221),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              preview,
                              style: const TextStyle(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
