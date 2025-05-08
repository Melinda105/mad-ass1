import 'dart:convert'; // Import the dart:convert package to handle encoding and decoding, particularly for base64 image data.
import 'package:ass1/user_modal.dart'; // Import the UserModel class for managing the current user's data.
import 'package:flutter/material.dart'; // Import Flutter Material Design widgets for UI elements.
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for working with Firebase Firestore database.

class SharePostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post; // The post data (title, description, etc.) passed to the screen.
  final String postId; // The unique ID of the post to display.
  final UserModel currentUser; // The current user who is viewing the post.

  // Constructor to receive post, postId, and currentUser.
  SharePostDetailScreen({
    required this.post,
    required this.postId,
    required this.currentUser,
  });

  @override
  _SharePostDetailScreenState createState() => _SharePostDetailScreenState(); // Create the state for this screen.
}

class _SharePostDetailScreenState extends State<SharePostDetailScreen> {
  final TextEditingController _commentController = TextEditingController(); // Controller for the comment input field.

  // Method to submit a comment to Firestore
  void _submitComment() async {
    final text = _commentController.text.trim(); // Get the text entered by the user.

    // Get the current user's name from the Users collection in Firestore using their phone number.
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.currentUser.phone)
        .get();
    final currentUserName = userDoc.data()?['name'] ?? widget.currentUser.name; // Default to the user's name if it's not found.

    // Return if the comment text is empty.
    if (text.isEmpty) return;

    // Add the comment to the Firestore collection for the specific post.
    await FirebaseFirestore.instance
        .collection('share_posts') // Collection for share posts
        .doc(widget.postId) // Document representing the specific post
        .collection('comments') // Subcollection for comments on the post
        .add({
      'user': currentUserName, // Store the user's name who commented.
      'text': text, // Store the comment text.
      'timestamp': FieldValue.serverTimestamp(), // Store the timestamp of when the comment was added.
    });

    _commentController.clear(); // Clear the comment input field after submission.
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post; // Get the post data passed to this screen.

    return Scaffold(
      appBar: AppBar(title: Text(post['title'] ?? 'Details')), // Display the title of the post in the AppBar.
      body: ListView( // Use a ListView to display content in a scrollable format.
        children: [
          // Display the post's image if available; otherwise, display a gray placeholder.
          post['image'] != null && post['image'] != ''
              ? Image.memory(
            base64Decode(post['image']), // Decode the base64 image data.
            height: 250, // Set the height of the image.
            width: double.infinity, // Set the width of the image to fill the screen.
            fit: BoxFit.cover, // Ensure the image covers the area proportionally.
          )
              : Container(height: 250, color: Colors.grey), // Display a gray placeholder if no image is available.

          Padding(
            padding: const EdgeInsets.all(16.0), // Add padding around the content.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align the column content to the start.
              children: [
                // Display the post's title in a bold font.
                Text(post['title'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8), // Space between title and description.
                // Display the post's description.
                Text(post['description'] ?? ''),
                SizedBox(height: 8), // Space between description and price.
                // Display the price of the post.
                Text("RM ${post['price'] ?? '0'}"),
                SizedBox(height: 8), // Space between price and area.
                // Display the location of the post with an icon.
                Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 5),
                    Text(post['area'] ?? ''),
                  ],
                ),
                Divider(height: 32), // Divider line to separate the sections.

                // Display "Comments" heading in bold.
                Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),

                // StreamBuilder to listen for real-time updates on the comments.
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('share_posts') // Share posts collection.
                      .doc(widget.postId) // Post document by its ID.
                      .collection('comments') // Subcollection of comments for this post.
                      .orderBy('timestamp', descending: true) // Order comments by timestamp (newest first).
                      .snapshots(), // Listen for real-time updates on comments.
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator()); // Show loading spinner if data is not available.

                    final comments = snapshot.data!.docs; // List of comments retrieved from Firestore.
                    if (comments.isEmpty) {
                      // Display a message if there are no comments.
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text("No comments yet."),
                      );
                    }

                    // Display the list of comments.
                    return Column(
                      children: comments.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['user'] ?? 'User'), // Display the commenter's name.
                          subtitle: Text(data['text'] ?? ''), // Display the comment text.
                        );
                      }).toList(),
                    );
                  },
                ),

                // Row to display the comment input field and send button.
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController, // Text controller for the comment input.
                        decoration: InputDecoration(hintText: "Add a comment"), // Placeholder text.
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send), // Send icon.
                      onPressed: _submitComment, // Call the _submitComment method when the send button is pressed.
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
