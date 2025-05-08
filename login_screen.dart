import 'package:flutter/material.dart';
import 'database_service.dart'; // For database-related operations
import 'user_modal.dart'; // User model that holds the user data
import 'register_screen.dart'; // Register screen for new users
import 'forgot_password_screen.dart'; // Forgot password screen for recovery
import 'home.dart'; // Home screen after login

// LoginScreen widget to manage the login UI and logic
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// _LoginScreenState class for managing the state of LoginScreen widget
class _LoginScreenState extends State<LoginScreen> {
  // Controllers to handle input fields
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final dbService = DatabaseService(); // Database service instance

  // Function that handles the login process
  Future<void> _login() async {
    String phone = _phoneController.text.trim(); // Get the phone number entered
    String password = _passwordController.text; // Get the password entered

    // Check if either phone or password is empty, show an error if so
    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter phone and password");
      return;
    }

    // Fetch the user details from the database using the provided phone number
    UserModel? user = await dbService.getUserByPhone(phone);

    // If no user is found, show an error message
    if (user == null) {
      _showSnackBar("No account found with that phone number");
    } else {
      // If user is found, check if the password matches
      if (user.password == password) {
        // Show success message and navigate to the home screen
        _showSnackBar("Login Successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              currentUser: user, // Pass the logged-in user data to the HomeScreen
              addPost: (Map<String, String> newPost) { }, // Function placeholder
              posts: [], // Empty posts list for now
            ),
          ),
        );
      } else {
        // If password doesn't match, show error
        _showSnackBar("Invalid password");
      }
    }
  }

  // Function to show a Snackbar with a given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)), // Display the message in the SnackBar
    );
  }

  // Build method that defines the UI for the login screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Account"), // Title of the login screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the body content
        child: Column(
          children: [
            // Phone number input field
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"), // Label for input field
            ),
            // Password input field (password characters will be hidden)
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"), // Label for input field
              obscureText: true, // Hide the entered password
            ),
            const SizedBox(height: 20), // Space between the fields and the button
            // Login button that triggers the login function when pressed
            ElevatedButton(
              onPressed: _login, // Call the _login method when button is pressed
              child: const Text("Login"),
            ),
            // Button to navigate to the Register screen
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()), // Navigate to RegisterScreen
                );
              },
              child: const Text("Register Account"), // Button text
            ),
            // Button to navigate to the Forgot Password screen
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()), // Navigate to ForgotPasswordScreen
                );
              },
              child: const Text("Forgot Password?"), // Button text
            ),
          ],
        ),
      ),
    );
  }
}
