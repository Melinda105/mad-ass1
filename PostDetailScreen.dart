import 'dart:convert'; // Import the 'dart:convert' library to handle base64 decoding
import 'package:ass1/user_modal.dart'; // Import the 'UserModel' class for representing the current user
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore for accessing data
import 'package:flutter/material.dart'; // Import Flutter's Material Design library for UI components

// A StatelessWidget that displays the details of a post, including title, location, image, and comments
class PostDetailScreen extends StatelessWidget {
  // The post data and the current user passed into the constructor
  final Map<String, dynamic> post;
  final UserModel currentUser;

  // Constructor to initialize the post data and current user
  PostDetailScreen({required this.post, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Scaffold to hold the app bar and body content
    return Scaffold(
      appBar: AppBar(title: Text("Post Detail")), // AppBar with title
      body: Column(
        children: [
          // Expanded widget to allow the content to take the available space
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), // Padding around the content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
                children: [
                  // Post title
                  Text(
                    post['title'] ?? '', // Display the title or empty string if not available
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Post location
                  Text(
                    "Location: ${post['location'] ?? ''}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  // Display the post image if available
                  post['image'] != null && post['image'].toString().isNotEmpty
                      ? Image.memory(
                    base64Decode(post['image']), // Decode base64 image string
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover, // Scale the image to cover the available space
                  )
                      : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(child: Text("No Image")), // Placeholder for missing image
                  ),
                  SizedBox(height: 16),
                  // "Comments" section header
                  Text(
                    "Comments:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // StreamBuilder to listen to real-time updates from Firestore comments
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts') // Access the 'posts' collection
                        .doc(post['postId']) // Use the postId to get the specific post
                        .collection('comments') // Access the 'comments' subcollection
                        .orderBy('timestamp', descending: true) // Order comments by timestamp, newest first
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator(); // Show a loading indicator if data isn't available yet
                      final comments = snapshot.data!.docs; // Get the list of comments from the snapshot
                      return ListView(
                        shrinkWrap: true, // Allow the ListView to take only the required space
                        physics: NeverScrollableScrollPhysics(), // Disable scrolling as we are already in a scrollable view
                        children: comments.map((doc) {
                          final data = doc.data() as Map<String, dynamic>; // Get the comment data
                          return _buildCommentItem(data['user'], data['text']); // Build each comment item
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Comment input section (User can add comments)
          CommentInput(
            postId: post['postId'], // Pass postId to comment input widget
            currentUser: currentUser, // Pass currentUser to comment input widget
          ),
        ],
      ),
    );
  }

  // Helper function to build a comment item in the list
  Widget _buildCommentItem(String user, String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the user's name in bold
          Text(user, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          // Display the comment text
          Text(comment),
        ],
      ),
    );
  }
}

// A StatefulWidget to allow the user to input a comment
class CommentInput extends StatefulWidget {
  final String postId;
  final UserModel currentUser;

  // Constructor to initialize postId and currentUser
  CommentInput({required this.postId, required this.currentUser});

  @override
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _commentController = TextEditingController(); // Controller to handle text input

  // Function to submit a comment
  void _submitComment() async {
    final text = _commentController.text.trim(); // Get the trimmed text from the input field
    if (text.isEmpty) return; // Don't submit if the input is empty

    // Fetch the current user's name from Firestore (if available)
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.currentUser.phone) // Use the current user's phone number to fetch the document
        .get();

    // Get the user's name or use the default name from currentUser
    final currentUserName = userDoc.data()?['name'] ?? widget.currentUser.name;

    // Add the comment to the 'comments' subcollection of the post
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId) // Use the postId to reference the specific post
        .collection('comments') // Access the 'comments' subcollection
        .add({
      'user': currentUserName, // Store the user's name
      'text': text, // Store the comment text
      'timestamp': FieldValue.serverTimestamp(), // Store the timestamp of when the comment was added
    });

    // Clear the comment input field
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Input field for adding comments and a send button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          // TextField to input the comment
          Expanded(
            child: TextField(
              controller: _commentController, // Assign the controller to the TextField
              decoration: InputDecoration(
                hintText: "Add a comment...", // Hint text to guide the user
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Icon button to submit the comment
          IconButton(
            icon: Icon(Icons.send), // Send icon
            onPressed: _submitComment, // Trigger _submitComment when pressed
          ),
        ],
      ),
    );
  }
}
