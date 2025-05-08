import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_modal.dart';
import 'create_community.dart';
import 'community_chat_screen.dart';
import 'dart:convert'; // For decoding base64 image strings

// Stateless widget that shows a list of communities the user has joined
class CommunityListScreen extends StatelessWidget {
  final UserModel user; // The current user object passed into the screen

  const CommunityListScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = user; // Store the user for easy reference

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hides the back button
        title: const Text('My Communities'),
      ),

      // Main body using a StreamBuilder to listen to real-time updates of the user document
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.phone) // Assumes the user's phone number is the document ID
            .snapshots(),
        builder: (context, userSnapshot) {
          // Show loading spinner while waiting for data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if data is missing or user document doesn't exist
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('User data unavailable.'));
          }

          // Extract the list of joined community IDs
          List joinedCommunities = userSnapshot.data!.get('joinedCommunities') ?? [];

          return Column(
            children: [
              // Button to create a new community
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text("Create a new community"),
                  onTap: () {
                    // Navigate to the CreateCommunityScreen with the current user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateCommunityScreen(user: currentUser),
                      ),
                    );
                  },
                ),
              ),

              // Expanded widget to fill the remaining space with the community list
              Expanded(
                child: joinedCommunities.isEmpty
                    ? const Center(
                  child: Text('You have not joined any communities yet.'),
                )
                    : StreamBuilder<QuerySnapshot>(
                  // Get communities where the document ID is in the joined list
                  stream: FirebaseFirestore.instance
                      .collection('communities')
                      .where(FieldPath.documentId, whereIn: joinedCommunities)
                      .snapshots(),
                  builder: (context, communitySnapshot) {
                    // Show loading indicator while communities are loading
                    if (communitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Handle empty community results
                    if (!communitySnapshot.hasData || communitySnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No communities available.'));
                    }

                    // Get the list of community documents
                    final communities = communitySnapshot.data!.docs;

                    // Build a scrollable list of communities
                    return ListView.builder(
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        var community = communities[index];

                        return ListTile(
                          leading: CircleAvatar(
                            // Show the community image if available, otherwise show icon
                            backgroundImage: community['imageUrl'].isNotEmpty
                                ? MemoryImage(base64Decode(community['imageUrl']))
                                : null,
                            child: community['imageUrl'].isEmpty
                                ? const Icon(Icons.group, color: Colors.grey)
                                : null,
                          ),
                          title: Text(community['name']), // Community name
                          subtitle: Text(community['description']), // Community description
                          onTap: () {
                            // Navigate to the community chat screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityChatScreen(
                                  communityId: community.id,
                                  communityTitle: community['name'],
                                  currentUser: currentUser,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
