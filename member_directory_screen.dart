import 'package:flutter/material.dart'; // Importing Flutter's Material Design library
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore library for database interaction

// A StatelessWidget to display the list of members in a specific community
class MemberDirectoryScreen extends StatelessWidget {
  // Required parameters: the community ID and the current user's phone number
  final String communityId;
  final String currentUserPhone;

  // Constructor to receive the necessary parameters
  const MemberDirectoryScreen({
    Key? key,
    required this.communityId,
    required this.currentUserPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reference to the Firestore collection for the members of a specific community
    final membersRef = FirebaseFirestore.instance
        .collection('communities') // Access 'communities' collection
        .doc(communityId) // Use the provided community ID
        .collection('members'); // Access 'members' subcollection for that community

    return Scaffold(
      appBar: AppBar(title: const Text('Community Members')), // AppBar title indicating the current screen is for community members
      body: StreamBuilder<QuerySnapshot>( // StreamBuilder to listen to real-time updates from Firestore
        stream: membersRef.snapshots(), // Get real-time snapshots of the members collection
        builder: (context, snapshot) {
          // If data is not yet available, show a loading indicator
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          // Once the data is fetched, get the list of members from the snapshot
          final members = snapshot.data!.docs;

          // ListView.builder to display a scrollable list of members
          return ListView.builder(
            itemCount: members.length, // Set the number of items to the number of members
            itemBuilder: (context, index) {
              final memberData = members[index].data() as Map<String, dynamic>; // Get the member data from Firestore
              final phone = memberData['phone']; // Access the phone number of the member

              // FutureBuilder to fetch the details of the user (like name and email) using the phone number
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Users').doc(phone).get(), // Fetch user data from the 'Users' collection
                builder: (context, userSnap) {
                  // If user data is not available, display a loading text
                  if (!userSnap.hasData) {
                    return ListTile(title: Text("Loading..."));
                  }

                  // Once the user data is fetched, retrieve it
                  final user = userSnap.data!.data() as Map<String, dynamic>;
                  final isAdmin = memberData['role'] == 'admin'; // Check if the member is an admin
                  final isSelf = phone == currentUserPhone; // Check if the member is the current user

                  // Return the ListTile widget for each member
                  return ListTile(
                    leading: Icon(isAdmin ? Icons.verified_user : Icons.person), // Display a verified user icon for admins, or a default person icon
                    title: Text(user['name'] ?? 'Unknown'), // Display the user's name, or 'Unknown' if not available
                    subtitle: Text(user['email'] ?? ''), // Display the user's email if available
                    trailing: isAdmin // If the member is an admin, display the 'Admin' label
                        ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding around the label
                      decoration: BoxDecoration(
                        color: Colors.redAccent, // Background color for the 'Admin' label
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      child: Text('Admin', style: TextStyle(color: Colors.white, fontSize: 12)), // 'Admin' text with style
                    )
                        : null, // If not an admin, no trailing widget is added
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
