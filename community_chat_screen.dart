// Import necessary packages for UI, database, image handling, etc.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_modal.dart'; // Custom user model
import 'member_directory_screen.dart'; // Member list UI
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

// Main chat screen widget
class CommunityChatScreen extends StatefulWidget {
  final String communityId; // Firestore ID for the community
  final String communityTitle; // Community title shown in the app bar
  final UserModel currentUser; // Currently logged-in user

  const CommunityChatScreen({
    required this.communityId,
    required this.communityTitle,
    required this.currentUser,
    super.key,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _controller = TextEditingController(); // Controls the message input field
  String? replyingToText; // Stores the text of the message being replied to
  String? replyingToMessageId; // Stores the ID of the message being replied to

  // Determine if a member is an admin based on Firestore 'role' field
  bool getSafeIsAdmin(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return data != null && data['role'] == 'admin';
  }

  // Function to change the community avatar (admin-only)
  Future<void> _changeAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Pick image from gallery

    if (pickedFile == null) return;

    try {
      final imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes(); // Convert image to bytes
      final base64Image = base64Encode(imageBytes); // Encode image in base64

      // Update the community document with new avatar
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .update({'imageUrl': base64Image});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Community avatar updated')));
    } catch (e) {
      print('❌ Error updating avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update avatar')));
    }
  }

  // Send a new message to the community chat
  Future<void> _sendMessage() async {
    final text = _controller.text.trim(); // Get trimmed input
    if (text.isEmpty) return;

    final messagesRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages');

    // Get user name from Firestore (in case it's been updated)
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.currentUser.phone)
        .get();

    final currentUserName = userDoc.data()?['name'] ?? widget.currentUser.name;

    // Add the message to the 'messages' collection
    await messagesRef.add({
      'text': text,
      'sender': currentUserName,
      'senderPhone': widget.currentUser.phone,
      'isAdmin': false,
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': replyingToMessageId,
      'seenBy': [widget.currentUser.phone],
      'reactions': {},
    });

    // Reset the input field and reply state
    setState(() {
      _controller.clear();
      replyingToText = null;
      replyingToMessageId = null;
    });
  }

  // Handle leave (for regular users) or delete (for admins)
  void _handleLeaveOrDelete(bool isAdmin) async {
    final action = isAdmin ? "Delete" : "Leave";
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$action Community"),
        content: Text(isAdmin
            ? "Are you sure you want to permanently delete this community?"
            : "Are you sure you want to leave this community?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (confirm != true) return;

    if (isAdmin) {
      // Delete the community document entirely
      await FirebaseFirestore.instance.collection('communities').doc(widget.communityId).delete();
    } else {
      // Remove the user from the community's member list
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('members')
          .doc(widget.currentUser.phone)
          .delete();

      // Also update the user's own joinedCommunities list
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUser.phone)
          .update({'joinedCommunities': FieldValue.arrayRemove([widget.communityId])});
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAdmin ? "Community deleted" : "You left the community")));
    Navigator.pop(context); // Exit the chat screen
  }

  // Add or remove emoji reaction from a message
  void _addReaction(String messageId, String emoji) async {
    final msgRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .doc(messageId);

    // Use transaction to ensure consistency
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(msgRef);
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final Map<String, dynamic> reactions = Map.from(data['reactions'] ?? {});
      List users = List<String>.from(reactions[emoji] ?? []);

      if (users.contains(widget.currentUser.phone)) {
        users.remove(widget.currentUser.phone); // Remove reaction
      } else {
        users.add(widget.currentUser.phone); // Add reaction
      }
      reactions[emoji] = users;
      transaction.update(msgRef, {'reactions': reactions});
    });
  }

  // Mark a message as seen by the current user
  void _markAsSeen(String messageId) {
    final ref = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .doc(messageId);

    ref.update({'seenBy': FieldValue.arrayUnion([widget.currentUser.phone])});
  }

  // Pin a message in the community for everyone to see
  void _pinMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('meta')
        .doc('pinnedMessage')
        .set({
      'text': text,
      'pinnedAt': FieldValue.serverTimestamp(),
      'pinnedBy': widget.currentUser.phone,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Message pinned.")));
  }

  // Show the reply banner with quoted message
  void _showReplyBanner(String text, String messageId) {
    setState(() {
      replyingToText = text;
      replyingToMessageId = messageId;
    });
  }

  // Show dialog to edit community details (name, description, avatar)
  void _showEditDialog() async {
    final doc = await FirebaseFirestore.instance.collection('communities').doc(widget.communityId).get();
    final data = doc.data()!;
    final titleController = TextEditingController(text: data['name']);
    final descController = TextEditingController(text: data['description']);
    String avatarBase64 = data['imageUrl'] ?? '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edit Community"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: "Community Name")),
                TextField(controller: descController, decoration: InputDecoration(labelText: "Description")),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await File(pickedFile.path).readAsBytes();
                      setState(() {
                        avatarBase64 = base64Encode(bytes);
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: avatarBase64.isNotEmpty
                        ? MemoryImage(base64Decode(avatarBase64))
                        : null,
                    child: avatarBase64.isEmpty ? Icon(Icons.add_a_photo) : null,
                  ),
                ),
                Text("Tap to change avatar", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('communities').doc(widget.communityId).update({
                  'name': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'imageUrl': avatarBase64,
                });
                Navigator.pop(context);
                setState(() {}); // Refresh UI
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // Show bottom sheet with admin/user options (edit, manage members, leave/delete)
  void _showOptionsMenu(bool isAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit Community"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog();
                },
              ),
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.group_remove),
                title: Text("Manage Members"),
                onTap: () {
                  Navigator.pop(context);
                  _showMemberManagement();
                },
              ),
            ListTile(
              leading: Icon(isAdmin ? Icons.delete : Icons.logout),
              title: Text(isAdmin ? "Delete Community" : "Leave Community"),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _handleLeaveOrDelete(isAdmin);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show modal to manage members (admin-only)
  void _showMemberManagement() async {
    final membersRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('members');

    final snapshot = await membersRef.get();

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: snapshot.docs.where((doc) => doc.id != widget.currentUser.phone).map((doc) {
          final data = doc.data();
          return ListTile(
            title: Text(data['name'] ?? 'Unknown'),
            subtitle: Text(data['phone'] ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () async {
                await membersRef.doc(doc.id).delete();
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(doc.id)
                    .update({
                  'joinedCommunities': FieldValue.arrayRemove([widget.communityId])
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Member removed")));
                setState(() {});
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Main UI build method
  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    final memberRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('members')
        .doc(widget.currentUser.phone);

    final pinnedRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('meta')
        .doc('pinnedMessage');

    return FutureBuilder<DocumentSnapshot>(
      future: memberRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final isAdmin = getSafeIsAdmin(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('communities').doc(widget.communityId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) return Text(widget.communityTitle);
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final avatarBase64 = data['imageUrl'] ?? '';
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: avatarBase64.isNotEmpty ? MemoryImage(base64Decode(avatarBase64)) : null,
                      child: avatarBase64.isEmpty ? Icon(Icons.group) : null,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.communityTitle, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18)),
                    ),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.group),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberDirectoryScreen(
                        communityId: widget.communityId,
                        currentUserPhone: widget.currentUser.phone,
                      ),
                    ),
                  );
                },
              ),
              IconButton(icon: Icon(Icons.more_vert), onPressed: () => _showOptionsMenu(getSafeIsAdmin(snapshot.data!))),
            ],
          ),

          body: Column(
            children: [
              // Display pinned message
              StreamBuilder<DocumentSnapshot>(
                stream: pinnedRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || !(snap.data?.exists ?? false)) return SizedBox();
                  return Container(
                    width: double.infinity,
                    color: Colors.yellow[100],
                    padding: EdgeInsets.all(8),
                    child: Text("📌 ${snap.data!['text']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),

              // Display messages list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messagesRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final data = doc.data() as Map<String, dynamic>;
                        _markAsSeen(doc.id); // Mark message as seen

                        final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
                        final seenBy = List<String>.from(data['seenBy'] ?? []);
                        final isSender = data['senderPhone'] == widget.currentUser.phone;
                        final replyTo = data['replyTo'];

                        return GestureDetector(
                          onLongPress: () {
                            if (isAdmin) _pinMessage(data['text']);
                          },
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (replyTo != null)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('communities')
                                        .doc(widget.communityId)
                                        .collection('messages')
                                        .doc(replyTo)
                                        .get(),
                                    builder: (context, replySnap) {
                                      if (!replySnap.hasData || !replySnap.data!.exists) {
                                        return Text("↪️ Reply to: [message deleted]");
                                      }
                                      final replyData = replySnap.data!.data() as Map<String, dynamic>;
                                      return Text("↪️ ${replyData['sender'] ?? 'Unknown'}: ${replyData['text'] ?? ''}",
                                          style: TextStyle(fontSize: 11, color: Colors.grey));
                                    },
                                  ),
                                Text(data['sender'] ?? 'Unknown'),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['text'] ?? ''),
                                if (reactions.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    children: reactions.entries.map((e) {
                                      final emoji = e.key;
                                      final users = List<String>.from(e.value);
                                      return GestureDetector(
                                        onTap: () => _addReaction(doc.id, emoji),
                                        child: Chip(label: Text("$emoji ${users.length}")),
                                      );
                                    }).toList(),
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.emoji_emotions_outlined, size: 20),
                                      onPressed: () => _addReaction(doc.id, "👍"),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.reply, size: 20),
                                      onPressed: () => _showReplyBanner(data['text'], doc.id),
                                    ),
                                    if (isSender && seenBy.length > 1)
                                      Text("👁️ Seen by ${seenBy.length - 1}", style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // If replying, show reply banner
              if (replyingToText != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(child: Text("↪️ Replying to: $replyingToText")),
                      IconButton(icon: Icon(Icons.close), onPressed: () {
                        setState(() {
                          replyingToText = null;
                          replyingToMessageId = null;
                        });
                      })
                    ],
                  ),
                ),

              // Message input field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
