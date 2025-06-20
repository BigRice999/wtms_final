import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:wtms/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  File? _image;
  Uint8List? webImageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(
          "Registration",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 123, 77, 0),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 209, 138),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 100, 30, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD599), Colors.white],
            begin: Alignment.topCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color.fromARGB(255, 255, 204, 101)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: showSelectionDialog,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _image != null
                            ? _buildProfileImage()
                            : const AssetImage('assets/images/profile.png') as ImageProvider,
                      ),
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 14,
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                buildTextField(nameController, "Full Name"),
                buildTextField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                buildTextField(passwordController, "Password", obscureText: true),
                buildTextField(confirmPasswordController, "Confirm Password", obscureText: true),
                buildTextField(phoneController, "Phone", keyboardType: TextInputType.phone),
                buildTextField(addressController, "Address", maxLines: 5),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: registerUserDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 186, 87),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Register"),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text("Already have an account? Sign In"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
      ),
    );
  }

  void registerUserDialog() {
    String name = nameController.text;
    String email = emailController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String phone = phoneController.text;
    String address = addressController.text;

    final emailValid = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(email);
    final phoneValid = RegExp(r"^\d+").hasMatch(phone);

    if (name.isEmpty || email.isEmpty || password.isEmpty ||
        confirmPassword.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    if (!emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address"), backgroundColor: Colors.red),
      );
      return;
    }

    if (!phoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number"), backgroundColor: Colors.red),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Register this account?"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            child: const Text("YES"),
            onPressed: () {
              Navigator.of(context).pop();
              registerUser();
            },
          ),
          TextButton(
            child: const Text("CANCEL"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void registerUser() async {
    var url = Uri.parse("http://10.0.2.2/wtms_api/register_worker.php");
    var request = http.MultipartRequest('POST', url);
    request.fields['full_name'] = nameController.text;
    request.fields['email'] = emailController.text;
    request.fields['password'] = passwordController.text;
    request.fields['phone'] = phoneController.text;
    request.fields['address'] = addressController.text;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    var response = await request.send();
    var res = await http.Response.fromStream(response);
    if (res.statusCode == 200) {
      var jsondata = json.decode(res.body);
      if (jsondata['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Register Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsondata['message'] ?? "Failed to register"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void showSelectionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select from"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectFromCamera();
              },
              child: const Text("From Camera"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectfromGallery();
              },
              child: const Text("From Gallery"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      if (kIsWeb) {
        webImageBytes = await pickedFile.readAsBytes();
      }
      setState(() {});
    }
  }

  Future<void> _selectfromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {});
    }
  }

  ImageProvider _buildProfileImage() {
    if (_image != null) {
      if (kIsWeb && webImageBytes != null) {
        return MemoryImage(webImageBytes!);
      } else {
        return FileImage(_image!);
      }
    }
    return const AssetImage('assets/images/profile.png');
  }
}
