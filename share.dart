import 'dart:convert'; // Import the dart:convert package for encoding and decoding (e.g., for image data)
import 'package:ass1/user_modal.dart'; // Import the UserModel class to represent the current user
import 'package:flutter/material.dart'; // Import Flutter's Material Design widgets
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to interact with Firebase
import 'create_share_post_screen.dart'; // Import the screen to create a share post
import 'share_item_detail_screen.dart'; // Import the screen to view the details of a share post

// ShareScreen is a StatefulWidget that displays a list of share posts
class ShareScreen extends StatefulWidget {
  final UserModel currentUser; // The current user passed from the previous screen
  ShareScreen({required this.currentUser}); // Constructor to pass the current user

  @override
  _ShareScreenState createState() => _ShareScreenState(); // Create the corresponding state
}

class _ShareScreenState extends State<ShareScreen> {
  String selectedArea = ''; // Variable to store the selected area filter
  String selectedCondition = ''; // Variable to store the selected condition filter
  String searchQuery = ''; // Variable to store the search query for filtering

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF5FD), // Set the background color of the screen
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the back button on the AppBar
        backgroundColor: Color(0xFFFAF5FD), // Set the AppBar background color
        title: Text("Share", style: TextStyle(color: Colors.black)), // Set the title of the AppBar
        centerTitle: false, // Title is aligned to the left
      ),

      // Floating action button to navigate to the screen where the user can create a post
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[800],
        child: Icon(Icons.add, color: Colors.white), // Add icon inside the button
        onPressed: () {
          // Navigate to the CreateSharePostScreen when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateSharePostScreen(currentUser: widget.currentUser),
            ),
          );
        },
      ),

      // Main body of the screen
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the body content
        child: Column(
          children: [
            // Search bar for filtering posts based on title
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the search box
                borderRadius: BorderRadius.circular(12), // Rounded corners for the search box
                border: Border.all(color: Colors.grey.shade300), // Border color
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search', // Placeholder text
                  prefixIcon: Icon(Icons.search), // Search icon in the input field
                  border: InputBorder.none, // No border around the input field
                ),
                onChanged: (value) => setState(() => searchQuery = value), // Update search query on text change
              ),
            ),
            SizedBox(height: 12), // Space between search bar and dropdowns

            // Row to hold dropdowns for area and condition filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute dropdowns evenly
              children: [
                // Area dropdown for selecting a specific area
                DropdownButton<String>(
                  value: selectedArea.isEmpty ? null : selectedArea, // If no area is selected, show null
                  hint: Text("Area"), // Placeholder text for the dropdown
                  items: ["All", "Kuala Lumpur", "Petaling Jaya", "Subang"] // List of area options
                      .map((area) => DropdownMenuItem(value: area, child: Text(area))) // Map areas to DropdownMenuItems
                      .toList(),
                  onChanged: (val) => setState(() => selectedArea = val == "All" ? '' : val ?? ''), // Update selected area
                ),
                // Condition dropdown for selecting the condition of the item
                DropdownButton<String>(
                  value: selectedCondition.isEmpty ? "All" : selectedCondition, // Default value is "All" if no condition is selected
                  items: ["All", "New", "Used"] // List of condition options
                      .map((cond) => DropdownMenuItem(value: cond, child: Text(cond))) // Map conditions to DropdownMenuItems
                      .toList(),
                  onChanged: (val) => setState(() => selectedCondition = val == "All" ? '' : val ?? ''), // Update selected condition
                ),
              ],
            ),
            SizedBox(height: 12), // Space between dropdowns and the post list

            // StreamBuilder to listen for real-time updates from Firestore collection 'share_posts'
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('share_posts') // Firestore collection for share posts
                    .orderBy('timestamp', descending: true) // Order posts by timestamp (newest first)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator()); // Show a loading spinner if data is not available

                  // Filter the posts based on search query, selected area, and selected condition
                  final filtered = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toString().toLowerCase() ?? ''; // Get post title and convert to lowercase
                    final area = data['area'] ?? ''; // Get area of the post
                    final condition = data['condition'] ?? ''; // Get condition of the post
                    return (searchQuery.isEmpty || title.contains(searchQuery.toLowerCase())) && // Filter by search query
                        (selectedArea.isEmpty || selectedArea == area) && // Filter by selected area
                        (selectedCondition.isEmpty || selectedCondition == condition); // Filter by selected condition
                  }).toList();

                  // Display filtered posts in a grid view
                  return GridView.builder(
                    itemCount: filtered.length, // Set the number of items in the grid
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Display 2 items per row
                      crossAxisSpacing: 10, // Space between columns
                      mainAxisSpacing: 10, // Space between rows
                      childAspectRatio: 0.75, // Aspect ratio for each grid item
                    ),
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;
                      final docId = filtered[index].id; // Get the document ID for the post

                      return GestureDetector(
                        onTap: () {
                          // Navigate to the detail screen when a post is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SharePostDetailScreen(
                                post: data, // Pass post data to the detail screen
                                postId: docId, // Pass post ID to the detail screen
                                currentUser: widget.currentUser, // Pass the current user to the detail screen
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Card with rounded corners
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
                            children: [
                              Expanded(
                                child: data['image'] != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.memory(
                                    base64Decode(data['image']), // Decode the base64 image
                                    width: double.infinity, // Stretch the image to full width
                                    fit: BoxFit.cover, // Cover the available space with the image
                                  ),
                                )
                                    : Container(
                                  color: Colors.grey[300], // Default placeholder if no image is available
                                  child: Center(child: Icon(Icons.image, size: 50)), // Show an icon if no image
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)), // Display the post title
                                    SizedBox(height: 4), // Space between title and location
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.grey), // Location icon
                                        SizedBox(width: 4),
                                        Text(data['area'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey)), // Display the area
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
