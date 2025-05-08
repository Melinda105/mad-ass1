import 'dart:convert'; // Import the 'dart:convert' library to handle base64 decoding

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to interact with Firebase
import 'package:flutter/material.dart'; // Import Flutter Material Design widgets for UI components
import 'edit_profile_screen.dart'; // Import the EditProfileScreen to allow users to edit their profile

// ProfileScreen is a StatelessWidget that displays a user's profile information
class ProfileScreen extends StatelessWidget {
  final String userId; // userId is passed to this screen to fetch the user's details

  const ProfileScreen({super.key, required this.userId}); // Constructor to initialize the userId

  @override
  Widget build(BuildContext context) {
    // Scaffold is used to set up the basic structure of the app with an AppBar and body
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"), // AppBar title
        centerTitle: true, // Center the title in the AppBar
        automaticallyImplyLeading: false, // Prevent the back button from appearing in the AppBar
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // StreamBuilder listens for real-time updates from Firestore
        stream: FirebaseFirestore.instance.collection('Users') // Access 'Users' collection in Firestore
            .doc(userId) // Reference the document for the user using the userId
            .snapshots(), // Listen for changes to this specific user's data
        builder: (context, snapshot) {
          // If snapshot doesn't have data, show a loading indicator
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once data is available, extract user details from the snapshot
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] ?? ''; // Default to empty string if name is null
          final phone = userData['phone'] ?? ''; // Default to empty string if phone is null
          final email = userData['email'] ?? ''; // Default to empty string if email is null
          final imagePath = userData['profileImagePath'] ?? ''; // Default to empty string if profileImagePath is null

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Add padding for the profile content
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                children: [
                  // CircleAvatar widget to display the user's profile image
                  CircleAvatar(
                    radius: 50, // Radius of the circle (size of the avatar)
                    backgroundColor: Colors.grey[300], // Background color if no image is provided
                    backgroundImage: imagePath.isNotEmpty
                        ? MemoryImage(base64Decode(imagePath)) // Decode and display the image if available
                        : null, // Use the image if available, otherwise null
                    child: imagePath.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) // Default icon if no profile image
                        : null, // Do not show icon if profile image exists
                  ),

                  const SizedBox(height: 16), // Space between avatar and name
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)), // Display the user's name
                  const SizedBox(height: 4), // Space between name and phone number
                  Text("Phone: $phone"), // Display user's phone number
                  Text("Email: $email"), // Display user's email address
                  const SizedBox(height: 24), // Space before the buttons

                  // Edit Profile button
                  ElevatedButton(
                    onPressed: () async {
                      // Navigate to the EditProfileScreen when pressed
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            userId: userId, // Pass userId to EditProfileScreen
                            currentName: name, // Pass current name to EditProfileScreen
                            currentPhone: phone, // Pass current phone number to EditProfileScreen
                            currentEmail: email, // Pass current email to EditProfileScreen
                            currentProfileImagePath: imagePath, // Pass current image path to EditProfileScreen
                          ),
                        ),
                      );
                    },
                    child: const Text("Edit Profile"), // Button text
                  ),
                  const SizedBox(height: 10), // Space between buttons

                  // Logout button with icon
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to the login screen (replace current screen with the login screen)
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: Icon(Icons.logout), // Logout icon
                    label: Text("Logout"), // Button label
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
