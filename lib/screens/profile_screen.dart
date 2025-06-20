import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtms/models/worker.dart';
import 'package:wtms/screens/login_screen.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final Worker worker;

  const ProfileScreen({super.key, required this.worker});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  bool isEditing = false;
  bool isInitialized = false;

  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController birthController;
  String selectedGender = "";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    birthController = TextEditingController();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2/wtms_api/get_profile.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'worker_id': widget.worker.id}),
    );

    try {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final data = jsonData['data'];
        setState(() {
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          addressController.text = data['address'] ?? '';
          birthController.text = data['birth_date'] ?? '';
          selectedGender = data['gender'] ?? '';
          imageUrl = data['image'] ?? '';
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("JSON Decode Error: $e");
      debugPrint("Raw Body: ${response.body}");
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.0.2.2/wtms_api/update_profile_image.php"),
    );
    request.fields['id'] = widget.worker.id;
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final jsonData = json.decode(res.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          _image = null;
          imageUrl = jsonData['image'] + '?t=${DateTime.now().millisecondsSinceEpoch}';
        });
        fetchProfile();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      await _uploadProfileImage(_image!);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveProfile() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2/wtms_api/update_profile.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'worker_id': widget.worker.id,
        'name': widget.worker.name, 
        'email': emailController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'birth_date': birthController.text,
        'gender': selectedGender,
      }),
    );

    final jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      setState(() => isEditing = false);
      fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${jsonData['message']}"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to LOG OUT?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("LOG OUT", style: TextStyle(color: Color.fromARGB(255, 255, 0, 0))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('worker_id'); // Keep remember me if ticked before log in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }


  Widget _buildTextField(String label, TextEditingController controller,
      {bool isAddress = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 255, 207, 14)),
      ),
      child: TextField(
        controller: controller,
        maxLines: isAddress ? 5 : 1,
        readOnly: !isEditing || onTap != null,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  Future<void> _selectDate() async {
    if (!isEditing) return;
    final picked = await showDatePicker( // select birth date from calendar between 1950~2100
      context: context,
      initialDate: DateTime.tryParse(birthController.text) ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        birthController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(
          "My Profile", 
        style: TextStyle(
                fontSize: 25, 
                fontWeight: FontWeight.bold ,
                color: Color.fromARGB(255, 218, 131, 0)
                )
        ),
        
        backgroundColor: Colors.transparent,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 190, 126), Colors.white],
            begin: Alignment.topCenter,
          ),
        ),
        
        padding: const EdgeInsets.fromLTRB(30, 130, 30, 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: CircleAvatar( // profile picture
                          radius: 65,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (imageUrl.isNotEmpty
                                  ? NetworkImage("http://10.0.2.2/wtms_api/$imageUrl")
                                  : const AssetImage('assets/images/profile.png')) as ImageProvider,
                        ),
                      ),

                      Positioned( // camera icon at the bottom right of avatar
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(5),
                            child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.worker.name, // display user name
                            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
                            ),

                        const SizedBox(height: 6), // box to display ID
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(color: const Color.fromARGB(221, 88, 19, 19), borderRadius: BorderRadius.circular(10)),
                          child: Text("ID: ${widget.worker.id}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 1), // row for edit icon
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => isEditing ? saveProfile() : setState(() => isEditing = true),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white, size: 25),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 5), // container for the data allowed to edit only
              _buildTextField("Email", emailController),
              _buildTextField("Phone Number", phoneController),
              _buildTextField("Address", addressController, isAddress: true),
              _buildTextField("Birth Date", birthController, onTap: _selectDate),
             
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color.fromARGB(255, 228, 246, 158)),
                ),

                child: DropdownButtonFormField<String>( // drop down to select Male of Female for gender
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  value: selectedGender.isNotEmpty ? selectedGender : null,
                  items: ["Male", "Female"]
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: isEditing ? (val) => setState(() => selectedGender = val!) : null,
                ),
              ),

              ElevatedButton( // NEW: moving LOG OUT button to the bottom of My Profile
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("LOG OUT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
