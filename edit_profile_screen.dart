// Importing required Dart and Flutter libraries
import 'dart:convert'; // For base64 encoding/decoding
import 'dart:io'; // For working with files
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images from gallery
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images to Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // For updating Firestore user data

// A screen to edit user's profile info
class EditProfileScreen extends StatefulWidget {
  final String userId; // User ID used in Firestore document
  final String currentName; // User's current name
  final String currentPhone; // User's current phone
  final String currentEmail; // User's current email
  final String currentProfileImagePath; // Profile image stored as base64 string

  const EditProfileScreen({
    Key? key,
    required this.userId,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentProfileImagePath,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for input fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  File? _profileImage; // Selected new image file
  final _picker = ImagePicker(); // Instance to pick images
  bool _isLoading = false; // Loading state for save action

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  // Opens gallery to let user pick a profile image
  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // Uploads image to Firebase Storage and returns download URL
  Future<String?> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images/${widget.userId}.jpg'); // Set path in storage
    await ref.putFile(image); // Upload file
    return await ref.getDownloadURL(); // Get image URL
  }

  // Saves the updated user profile to Firestore
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true); // Show loading indicator

    String? base64Image;
    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes(); // Read image bytes
      base64Image = base64Encode(bytes); // Convert to base64 string
    }

    // Update user document in 'Users' collection
    await FirebaseFirestore.instance.collection('Users').doc(widget.userId).update({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      if (base64Image != null) 'profileImagePath': base64Image, // Optional field
    });

    setState(() => _isLoading = false); // Hide loading indicator
    Navigator.pop(context); // Close the screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile image display and picker
            GestureDetector(
              onTap: _pickProfileImage, // On tap, pick image
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) // Show new picked image
                    : (widget.currentProfileImagePath.isNotEmpty
                    ? MemoryImage(base64Decode(widget.currentProfileImagePath))
                as ImageProvider // Decode base64 image
                    : null), // If no image, show default
                child: _profileImage == null &&
                    widget.currentProfileImagePath.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Tap to change profile picture"), // Label text
            const SizedBox(height: 20),

            // Name input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            // Phone input
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            // Email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
