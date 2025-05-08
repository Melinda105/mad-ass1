import 'dart:convert'; // Import the dart:convert package to encode images to base64
import 'dart:io'; // Import dart:io to work with files (specifically, image files in this case)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to interact with Firebase
import 'package:flutter/material.dart'; // Import Flutter's Material Design widgets
import 'package:image_picker/image_picker.dart'; // Import image_picker to allow users to pick images from their gallery
import 'database_service.dart'; // Import a custom class for interacting with a local database
import 'user_modal.dart'; // Import the UserModel class that represents user data

// RegisterScreen is a StatefulWidget where users can register an account
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for text fields to capture user input
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable to hold the profile image selected by the user
  File? _profileImage;

  // ImagePicker instance for picking images from the gallery
  final ImagePicker _picker = ImagePicker();

  // DatabaseService instance to interact with the local SQLite database
  final dbService = DatabaseService();

  // Function to allow the user to pick a profile image from the gallery
  Future<void> _pickProfileImage() async {
    // Picking an image from the gallery using ImagePicker
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    // If an image is selected, update the state with the selected image file
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Function to handle the registration process
  Future<void> _register() async {
    // Capture input values from the text controllers
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    // Check if any of the fields are empty, and show a message if they are
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    // Encode the profile image to base64 format if it is selected
    String base64Image = '';
    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes(); // Read the image as bytes
      base64Image = base64Encode(bytes); // Encode the bytes to base64
    }

    // Create a UserModel object with the data entered by the user
    UserModel newUser = UserModel(
      name: name,
      phone: phone,
      email: email,
      password: password,
      profileImagePath: base64Image, // Store the base64 image
    );

    try {
      // Save the user to the local SQLite database
      await dbService.insertUser(newUser);

      // Save the user details to Firestore database
      await FirebaseFirestore.instance.collection('Users').doc(phone).set({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'profileImagePath': base64Image, // Store the base64 image in Firestore
        'joinedCommunities': [], // Initialize empty list of joined communities
      });

      // Show a success message and pop the current screen
      _showSnackBar("Account registered successfully!");
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      // If registration fails, show an error message
      print("Registration error: $e");
      _showSnackBar("Registration failed. Phone/Email might already be used.");
    }
  }

  // Function to display a SnackBar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The build method returns the UI layout for the Register screen
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Account"), // AppBar title
      ),
      body: SingleChildScrollView( // Allow the body to scroll if the content overflows
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TextField for name input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            // TextField for phone number input
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            // TextField for email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            // TextField for password input (password is hidden)
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true, // Hide the password input
            ),
            const SizedBox(height: 10),
            // Show the profile image if it's selected
            _profileImage != null
                ? CircleAvatar(
              radius: 40,
              backgroundImage: FileImage(_profileImage!),
            )
                : const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person), // Default icon if no profile image
            ),
            // Button to pick a profile image
            TextButton.icon(
              onPressed: _pickProfileImage, // Pick image on press
              icon: const Icon(Icons.image),
              label: const Text("Select Profile Picture"),
            ),
            const SizedBox(height: 20),
            // Button to submit registration form
            ElevatedButton(
              onPressed: _register, // Call _register function on press
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
