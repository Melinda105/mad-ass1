// Importing required packages:
// - cloud_firestore: For interacting with Firestore database
// - flutter/material.dart: For building the UI of the app
// - database_service.dart: Custom file to handle database operations like fetching user and updating password
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database_service.dart'; // Custom database service for handling operations

// Creating a stateful widget for Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// The state class for ForgotPasswordScreen widget
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // TextEditingControllers to get the values entered by the user in the text fields
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  // Instance of DatabaseService to interact with the Firestore database
  final dbService = DatabaseService();

  // Function to handle the password reset process
  Future<void> _resetPassword() async {
    // Getting user input values for phone and passwords
    String phone = _phoneController.text.trim();  // Removing spaces from phone number
    String newPassword = _newPasswordController.text;
    String repeatPassword = _repeatPasswordController.text;

    // Validation: Checking if any of the fields are empty
    if (phone.isEmpty || newPassword.isEmpty || repeatPassword.isEmpty) {
      // Show a snack bar with the message if any field is empty
      _showSnackBar("Please fill in all fields");
      return; // Stop further execution
    }

    // Validation: Checking if the new password and the repeated password match
    if (newPassword != repeatPassword) {
      // Show a snack bar if passwords don't match
      _showSnackBar("Passwords do not match");
      return; // Stop further execution
    }

    // Fetch user data by phone number using the custom DatabaseService
    final user = await dbService.getUserByPhone(phone);

    // Validation: If no user is found with the given phone number, show a snack bar
    if (user == null) {
      _showSnackBar("No account found with that phone number");
      return; // Stop further execution
    }

    // Update password in the custom database through the DatabaseService
    await dbService.updatePassword(phone, newPassword);

    // Update password in Firestore
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(phone)
        .update({'password': newPassword});  // Updating password in Firestore

    // Show a success message after the password is successfully updated
    _showSnackBar("Password updated successfully!");

    // Pop the current screen (go back to the login screen)
    Navigator.pop(context);
  }

  // Helper function to show a SnackBar with a custom message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // The UI part: Building the Forgot Password Screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"), // App bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding for the body content
        child: Column(
          children: [
            // Phone number input field
            TextField(
              controller: _phoneController, // Controller to retrieve the input
              decoration: const InputDecoration(labelText: "Phone Number"), // Label for the field
            ),

            // New password input field
            TextField(
              controller: _newPasswordController, // Controller to retrieve the input
              decoration: const InputDecoration(labelText: "New Password"), // Label for the field
              obscureText: true, // Obscure the text to hide the password
            ),

            // Repeat new password input field
            TextField(
              controller: _repeatPasswordController, // Controller to retrieve the input
              decoration: const InputDecoration(labelText: "Repeat New Password"), // Label for the field
              obscureText: true, // Obscure the text to hide the password
            ),

            const SizedBox(height: 20), // Adds space between the fields and the button

            // Reset password button
            ElevatedButton(
              onPressed: _resetPassword, // Calls the _resetPassword function when pressed
              child: const Text("Reset Password"), // Text on the button
            ),
          ],
        ),
      ),
    );
  }
}
