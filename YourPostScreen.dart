import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YourPostsScreen extends StatelessWidget {
  final String userId; // This is the profile's userId passed from ProfileScreen

  // Constructor to initialize the userId passed from another screen (ProfileScreen)
  YourPostsScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Posts"), // Title of the screen displayed in the AppBar
      ),
      body: StreamBuilder<QuerySnapshot>( // StreamBuilder listens to real-time updates from Firestore
        stream: FirebaseFirestore.instance
            .collection('posts') // Reference to the 'posts' collection in Firestore
            .where('userId', isEqualTo: userId) // Filter posts where the 'userId' field matches the passed userId
            .orderBy('createdAt', descending: true) // Order the posts by 'createdAt' field in descending order (latest first)
            .snapshots(), // Listen to real-time updates on the 'posts' collection
        builder: (context, snapshot) {
          // Check if the snapshot has data or is still loading
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator()); // Show loading indicator while data is being fetched
          }

          final posts = snapshot.data!.docs; // Retrieve the list of documents from the Firestore snapshot
          return ListView.builder( // ListView.builder for displaying posts dynamically
            itemCount: posts.length, // Set the number of items based on the number of posts fetched
            itemBuilder: (context, index) {
              final post = posts[index]; // Get each post document from the list of posts
              return ListTile( // Display each post in a ListTile widget
                title: Text(post['title']), // Display the title of the post
                subtitle: Text(post['location']), // Display the location of the post
                leading: post['image'] != null ? Image.network(post['image']) : null, // Display the image if available, otherwise show null
                trailing: Text(post['emoji']), // Display the emoji associated with the post on the right side
              );
            },
          );
        },
      ),
    );
  }
}
