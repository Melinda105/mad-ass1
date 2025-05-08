import 'dart:convert';
import 'dart:io'; // Required for file operations like picking an image
import 'package:firebase_storage/firebase_storage.dart'; // Required for Firebase storage to store images
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:image_picker/image_picker.dart'; // For picking images from gallery
import 'package:cloud_firestore/cloud_firestore.dart'; // For interacting with Firestore database
import 'package:ass1/PostDetailScreen.dart'; // Import for Post Detail screen
import 'YourPostScreen.dart'; // Import for Your Post screen
import 'package:ass1/user_modal.dart'; // Import the UserModel class
import 'share.dart'; // Import Share screen
import 'user_modal.dart'; // Import the UserModel class again
import 'community_list.dart'; // Import the Community List screen
import 'community_chat_screen.dart'; // Import the Community Chat screen
import 'profile_screen.dart'; // Import the Profile screen

// HomeScreen widget class which takes a currentUser object and other required data
class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  HomeScreen({
    required this.currentUser,
    required List posts, // List of posts
    required Null Function(Map<String, String> newPost) addPost, // Function to add a new post
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Keeps track of the selected tab index in the bottom navigation bar
  int _selectedIndex = 0;

  // Controller for the search bar
  final TextEditingController _searchController = TextEditingController();

  // Store search query input
  String _searchQuery = '';

  // Track which tab is selected ('Post' or 'Community')
  String _selectedTab = 'Post';

  // Dummy list of posts, would be fetched from Firestore in a real application
  List<Map<String, String>> posts = [
    {
      "title": "First post!",
      "location": "Kuala Lumpur",
      "image": "",
      "emoji": "😊"
    },
    {
      "title": "Exploring Flutter",
      "location": "Johor",
      "image": "",
      "emoji": "📱"
    }
  ];

  // Function to add a new post
  void addPost(Map<String, String> post) {
    post['userId'] = widget.currentUser.id.toString();
    setState(() {
      posts.insert(0, post);
    });
  }

 // List of pages for the bottom navigation (Home, Share, Community, Profile)
  List<Widget> _pages() {
    return [
      Column(
        children: [
          _buildSearchToggle(),
          Expanded(
            child: _selectedTab == 'Post'
                ? _buildPostTab()
                : _buildCommunityTab(),
          ),
        ],
      ),
      ShareScreen(currentUser: widget.currentUser),
      CommunityListScreen(user: widget.currentUser),
      ProfileScreen(
        userId: widget.currentUser.phone,
      ),

    ];
  }
  // Widget for building the search bar and the "Post" and "Community" tab buttons
  Widget _buildSearchToggle() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Search Share2U",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;// Update search query on text change
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton("Post"),
            _buildTabButton("Community"),
          ],
        ),
      ],
    );
  }

  // Build individual tab button for "Post" or "Community"
  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTab = label;
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black,
          backgroundColor: isSelected ? Colors.grey[800] : Colors.grey[300],
          shape: StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }
  // Build the "Post" tab with posts and search functionality
  Widget _buildPostTab() {
    return Column(
      children: [
        // "What's on your mind?" row with add post button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.add_box_outlined, size: 30.0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(
                        addPost: addPost,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              Expanded(child: Text("What’s on your mind?")),
            ],
          ),
        ),

        // Post list from firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final allPosts = snapshot.data!.docs;

              // Filter based on search keyword (title)
              final filteredPosts = allPosts.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                return _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredPosts.isEmpty) {
                return Center(child: Text("No matching posts found."));
              }

              return ListView.builder(
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final doc = filteredPosts[index];
                  final rawData = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final safeData = {
                    'postId': docId,
                    'title': rawData['title'] ?? '',
                    'location': rawData['location'] ?? '',
                    'emoji': rawData['emoji'] ?? '',
                    'image': rawData['image'] ?? '',
                    'userId': rawData['userId']?.toString() ?? '',
                  };

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: safeData,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                    child: PostCard(
                      title: safeData["title"] ?? '',
                      location: safeData["location"] ?? '',
                      imagePath: safeData["image"] ?? '',
                      emoji: safeData["emoji"] ?? '',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

// Build the "Community" tab with community search and join functionality
  Widget _buildCommunityTab() {
    return _searchQuery.isEmpty
        ? Center(child: Text("Search a keyword to find communities."))
        : FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUser.phone)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }


        final joined = userSnapshot.data!.get('joinedCommunities') ?? [];


        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('communities')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final communities = snapshot.data!.docs.where((doc) {
              final name = (doc['name'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList();


            if (communities.isEmpty) {
              return Center(child: Text("No matching communities found"));
            }


            return ListView.builder(
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                final name = community['name'] ?? 'Unnamed';
                final id = community.id;
                final image = community['imageUrl'];
                final desc = community['description'] ?? '';
                final createdByPhone = community['createdBy']?['phone'];
                final bool isCreator = createdByPhone == widget.currentUser.phone;
                final bool isJoined = joined.contains(id);


                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: image != null && image.isNotEmpty
                        ? MemoryImage(base64Decode(image))
                        : null,
                    child: image == null || image.isEmpty
                        ? Icon(Icons.group, color: Colors.grey)
                        : null,
                  ),

                  title: Text(name),
                  subtitle: Text(
                    isCreator || isJoined ? 'Tap to chat' : 'Tap to join and chat',
                  ),
                  trailing: isCreator || isJoined
                      ? IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityChatScreen(
                            communityId: id,
                            communityTitle: name,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  )
                      : ElevatedButton(
                    child: Text("Join"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Join Community"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (image != null && image.isNotEmpty)
                                Image.memory(base64Decode(image), height: 100),
                              SizedBox(height: 8),
                              Text("Community: $name"),
                              SizedBox(height: 4),
                              Text("Description: $desc"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text("Cancel"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              child: Text("Join"),
                              onPressed: () async {
                                Navigator.pop(context);
                                await FirebaseFirestore.instance
                                    .collection('communities')
                                    .doc(id)
                                    .collection('members')
                                    .doc(widget.currentUser.phone)
                                    .set({
                                  'name': widget.currentUser.name,
                                  'phone': widget.currentUser.phone,
                                  'email': widget.currentUser.email,
                                  'joinedAt': FieldValue.serverTimestamp(),
                                  'localId': widget.currentUser.id,
                                  'role': 'member',
                                });


                                await FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(widget.currentUser.phone)
                                    .set({
                                  'joinedCommunities': FieldValue.arrayUnion([id])
                                }, SetOptions(merge: true));


                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(content: Text("You joined $name")),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the default back button in the AppBar
        title: Row(
          children: [
            // Display a custom logo image in the title
            Image.asset(
              'assets/images/new-logo.png', // The path to the image
              height: 32, // Adjust the image size
            ),
            const SizedBox(width: 8), // Add space between the image and the text
            const Text("Share2U"), // App name displayed next to the logo
          ],
        ),
      ),
      body: _pages()[_selectedIndex], // Displays the content of the selected tab (Home, Share, etc.)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Set background color of the navigation bar
        selectedItemColor: Colors.black, // Color for the selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        currentIndex: _selectedIndex, // Tracks the current index of the selected tab
        type: BottomNavigationBarType.fixed, // Set type to fixed for consistent item placement
        onTap: (index) { // When an item is tapped, update the selected index
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: "Share"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  final Function(Map<String, String>) addPost; // Callback function to add the post
  final UserModel currentUser; // The current user who is creating the post

  CreatePostScreen({required this.addPost, required this.currentUser});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Controllers to handle text inputs
  final TextEditingController postController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController emojiController = TextEditingController();

  // File to hold the selected image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker(); // Instance to pick images

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to publish the post
  void _publishPost() async {
    if (postController.text.isEmpty && _selectedImage == null) {
      // If no text and image are provided, show a snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter text or select an image.")),
      );
      return;
    }

    String base64Image = '';
    // If an image is selected, encode it to base64 for storage
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    // Create the post data to store in Firestore
    Map<String, String> newPost = {
      "title": postController.text,
      "location": locationController.text,
      "emoji": emojiController.text,
      "image": base64Image,
      "userId": widget.currentUser.id.toString(),
    };

    final docRef = await FirebaseFirestore.instance.collection('posts').add({
      ...newPost,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
    });

    // Add the Firestore document ID to the post data
    newPost['postId'] = docRef.id;

    // Call the callback function to update the local UI
    widget.addPost(newPost);

    Navigator.pop(context); // Close the CreatePostScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Post")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: postController,
              decoration: InputDecoration(
                hintText: "What’s on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: "Enter location (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: emojiController,
              decoration: InputDecoration(
                hintText: "Add emoji (e.g. 😊)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Display the selected image, or a placeholder if no image is selected
            _selectedImage != null
                ? Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(child: Text("No image selected")),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                // Button to pick an image from the gallery
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text("Pick Image"),
                ),
                SizedBox(width: 10),
                // Button to publish the post
                ElevatedButton(
                  onPressed: _publishPost,
                  child: Text("Publish"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String location;
  final String imagePath;
  final String emoji;

  PostCard({
    required this.title,
    required this.location,
    required this.imagePath,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: EdgeInsets.all(8.0),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagePath.isNotEmpty
              ? Image.memory(
                base64Decode(imagePath),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
              : Container(
            height: 150,
            color: Colors.grey[300],
            child: Center(child: Icon(Icons.image, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "$emoji $title", // Combine emoji and title for the post
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16),
                  SizedBox(width: 4),
                  Text(location),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CommentInput extends StatefulWidget {
  final String postId; // ID of the post being commented on
  final UserModel currentUser; // Current user who is submitting the comment

  CommentInput({required this.postId, required this.currentUser});

  @override
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _commentController = TextEditingController();

  // Function to submit a comment
  void _submitComment() async {
    final text = _commentController.text.trim();
    // Get the current user's name
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.currentUser.phone)
        .get();
    final currentUserName = userDoc.data()?['name'] ?? widget.currentUser.name;
    if (text.isEmpty) return; // Don't submit if the comment is empty

    // Add the comment to Firestore
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'user': currentUserName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear(); // Clear the comment input field
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _submitComment, // Submit comment when pressed
          ),
        ],
      ),
    );
  }
}
