import 'package:flutter/material.dart'; // Importing Flutter's Material Design library
import 'package:firebase_core/firebase_core.dart'; // Import Firebase initialization
import 'login_screen.dart'; // Import the login screen
import 'register_screen.dart'; // Import the register screen
import 'home.dart'; // Import the home screen
import 'user_modal.dart'; // Import user model for user data handling
import 'database_service.dart'; // Import database service for managing user data

void main() async {
  // Ensures Flutter is fully initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase in your application
  await Firebase.initializeApp();

  // Simulate loading the last logged-in user (using custom logic for local storage or SQLite)
  final dbService = DatabaseService(); // Instance of the DatabaseService to interact with the database
  final UserModel? loggedInUser = await dbService.getLastLoggedInUser(); // Fetch the last logged-in user from the database

  // Runs the app and passes the logged-in user data to MyApp widget
  runApp(MyApp(loggedInUser: loggedInUser));
}

// MyApp widget that sets up the MaterialApp, including themes and routing
class MyApp extends StatelessWidget {
  const MyApp({Key? key, this.loggedInUser}) : super(key: key);

  // Declare a field to store the logged-in user, passed from main()
  final UserModel? loggedInUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share2U Demo', // Title of the app
      theme: ThemeData(
        primarySwatch: Colors.green, // Set the primary theme color to green
      ),
      home: const WelcomeScreen(), // Set WelcomeScreen as the home screen
      routes: {
        '/login': (_) => const LoginScreen(), // Define the route for the login screen
        '/register': (_) => const RegisterScreen(), // Define the route for the register screen
      },
    );
  }
}

// WelcomeScreen widget which is shown when the app starts
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F5), // Set the background color for the screen
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0), // Horizontal padding for content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
            children: [
              const Text(
                "Welcome to Share2U !", // Welcome message
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Text style for the message
              ),
              const SizedBox(height: 20), // Space between text and image
              Image.asset(
                'assets/images/new-logo.png', // Display the app logo image
                height: 100, // Set the logo height
              ),
              const SizedBox(height: 40), // Space between image and buttons
              CustomButton(
                text: "Login Account", // Text for the login button
                onPressed: () => Navigator.pushNamed(context, '/login'), // Navigate to the login screen when pressed
              ),
              const SizedBox(height: 20), // Space between buttons
              const Text("New User?", style: TextStyle(fontSize: 16)), // Text asking if the user is new
              const SizedBox(height: 10), // Space between text and register button
              CustomButton(
                text: "Register Account", // Text for the register button
                onPressed: () => Navigator.pushNamed(context, '/register'), // Navigate to the register screen when pressed
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CustomButton widget to create buttons with consistent style
class CustomButton extends StatelessWidget {
  final String text; // Text to display on the button
  final VoidCallback onPressed; // The callback function to call when the button is pressed

  const CustomButton({required this.text, required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.info_outline, color: Colors.black), // Icon to display on the button
      label: Text(
        text, // Button text passed from parent widget
        style: const TextStyle(color: Colors.black), // Button text color
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50), // Full width button with fixed height
        backgroundColor: Colors.white, // White background for the button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        side: const BorderSide(color: Colors.grey), // Grey border around the button
        elevation: 3, // Slight elevation for shadow effect
      ),
      onPressed: onPressed, // When the button is pressed, call the onPressed callback
    );
  }
}
