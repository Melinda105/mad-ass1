// Importing necessary Flutter and third-party packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For using Firestore database
import 'package:image_picker/image_picker.dart'; // For picking images from gallery
import 'dart:io'; // For File operations
import 'dart:convert'; // For base64 encoding
import 'user_modal.dart'; // Custom model for user information

// Stateful widget to manage form inputs and image picking
class CreateCommunityScreen extends StatefulWidget {
  final UserModel user; // The user creating the community

  const CreateCommunityScreen({Key? key, required this.user}) : super(key: key);

  @override
  _CreateCommunityScreenState createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  // Controllers for form inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isCreating = false; // Indicates if community is being created
  File? _selectedImage; // Holds the image selected by the user
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Opens the gallery to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Store picked image as a File
      });
      print('✅ Image selected: ${pickedFile.path}');
    } else {
      print('❌ No image selected.');
    }
  }

  // Converts an image file to a base64 string to store in Firestore
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes(); // Read image as bytes
      return base64Encode(bytes); // Encode as base64 string
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  // Handles the creation of a new community
  Future<void> _createCommunity() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    // Validation: Check if name or description is empty
    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    setState(() {
      _isCreating = true; // Show loading indicator
    });

    String? imageBase64;
    if (_selectedImage != null) {
      imageBase64 = await convertImageToBase64(_selectedImage!); // Convert image
    }

    try {
      // Add community document to 'communities' collection
      final newCommunity = await FirebaseFirestore.instance
          .collection('communities')
          .add({
        'name': name,
        'description': description,
        'imageUrl': imageBase64,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': {
          'name': widget.user.name,
          'phone': widget.user.phone,
          'email': widget.user.email,
          'localId': widget.user.id,
          'role': "admin",
        }
      });

      // Add current user as member (admin) of the community
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(newCommunity.id)
          .collection('members')
          .doc(widget.user.phone)
          .set({
        'name': widget.user.name,
        'phone': widget.user.phone,
        'email': widget.user.email,
        'joinedAt': FieldValue.serverTimestamp(),
        'localId': widget.user.id,
        'role': 'admin', // Role for the member
      });

      // Update user's joinedCommunities array
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user.phone)
          .set({
        'joinedCommunities': FieldValue.arrayUnion([newCommunity.id])
      }, SetOptions(merge: true)); // Merge with existing data

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating community: $e')),
      );
    }

    setState(() {
      _isCreating = false; // Stop loading indicator
    });
  }

  // Clean up controllers when the widget is disposed
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Community')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image picker container
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: Colors.grey[600]),
                    SizedBox(height: 5),
                    Text("Add photo", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Community name input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Community name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Description input
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Create button or loading indicator
            _isCreating
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _createCommunity,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
