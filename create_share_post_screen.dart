// Import necessary Dart and Flutter libraries
import 'dart:convert'; // For encoding image to base64
import 'dart:io'; // For File handling
import 'package:ass1/user_modal.dart'; // Your custom UserModel
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For selecting images
import 'package:cloud_firestore/cloud_firestore.dart'; // For using Firestore

// This screen allows users to create and share posts
class CreateSharePostScreen extends StatefulWidget {
  final UserModel currentUser; // User who is currently logged in

  // Constructor expects current user details
  CreateSharePostScreen({required this.currentUser});

  @override
  _CreateSharePostScreenState createState() => _CreateSharePostScreenState();
}

class _CreateSharePostScreenState extends State<CreateSharePostScreen> {
  // Controllers for input fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  // Dropdown values
  String selectedArea = '';
  String selectedCondition = '';

  // Image handling
  File? _image; // Stores the selected image file
  final picker = ImagePicker(); // For picking images from the gallery

  // Opens the image picker and updates the image
  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  // Submits the post to Firebase Firestore
  Future<void> _submitPost() async {
    // Basic validation to ensure title and image are provided
    if (_titleController.text.isEmpty || _image == null) return;

    // Read image bytes and convert to base64 string for storage
    final bytes = await _image!.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Fetch the user's name from Firestore if not already in UserModel
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.currentUser.phone)
        .get();
    final currentUserName = userDoc.data()?['name'] ?? widget.currentUser.name;

    // Add the post to the "share_posts" collection
    await FirebaseFirestore.instance.collection('share_posts').add({
      'title': _titleController.text,
      'description': _descController.text,
      'condition': selectedCondition,
      'price': _priceController.text,
      'area': selectedArea,
      'image': base64Image,
      'owner': currentUserName,
      'timestamp': FieldValue.serverTimestamp(), // For sorting posts by time
    });

    // Go back to the previous screen after posting
    Navigator.pop(context);
  }

  // Build method renders the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Share / Rent Your Stuff"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Title", _titleController, Icons.title),
                SizedBox(height: 10),
                _buildTextField("Description", _descController, Icons.description, maxLines: 3),
                SizedBox(height: 10),
                _buildTextField("Price (RM)", _priceController, Icons.money, keyboard: TextInputType.number),
                SizedBox(height: 10),
                _buildDropdown(
                  label: "Area",
                  value: selectedArea,
                  items: ["Kuala Lumpur", "Petaling Jaya", "Subang"],
                  onChanged: (val) => setState(() => selectedArea = val ?? ''),
                ),
                SizedBox(height: 10),
                _buildDropdown(
                  label: "Condition",
                  value: selectedCondition,
                  items: ["New", "Used"],
                  onChanged: (val) => setState(() => selectedCondition = val ?? ''),
                ),
                SizedBox(height: 16),

                // Image Picker Display
                GestureDetector(
                  onTap: _pickImage,
                  child: _image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text("Tap to select image", style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    child: Text("Post"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a styled text input field with icon
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Builds a styled dropdown selector with label
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text("Select $label", style: TextStyle(fontSize: 14)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
