// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'group_creation_screen.dart'; // Import the Main class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth
import 'group_screen.dart'; // Import the GroupScreen class
import 'auth.dart'; // Import the AuthenticationService class

class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({Key? key}) : super(key: key);

  @override
  _GroupJoinScreenState createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController(); // Add TextEditingController for username

  Future<void> joinGroup(
      BuildContext context, String groupCode, String username) async {
    try {
      // Get the current user's UID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get a reference to the Firestore collection containing groups
      CollectionReference groupsCollection =
          FirebaseFirestore.instance.collection('groups');

      // Query Firestore to find the group with the provided group code
      QuerySnapshot querySnapshot =
          await groupsCollection.where('groupCode', isEqualTo: groupCode).get();

      // Check if the group with the provided code exists
      if (querySnapshot.docs.isNotEmpty) {
        // Get the group document
        DocumentSnapshot groupSnapshot = querySnapshot.docs.first;

        // Add current user's UID to the group's members list
        await groupsCollection.doc(groupSnapshot.id).update({
          'members': FieldValue.arrayUnion([userId])
        });

        // Check if the user already exists in the leaderboard
        DocumentSnapshot leaderboardSnapshot = await groupsCollection
            .doc(groupSnapshot.id)
            .collection('leaderboard')
            .doc(userId)
            .get();

        if (!leaderboardSnapshot.exists) {
          // If the user does not exist in the leaderboard, add them
          await groupsCollection
              .doc(groupSnapshot.id)
              .collection('leaderboard')
              .doc(userId)
              .set({
            'username': username,
            'points': 0,
          });
        }

        // Navigate to the group screen if the user is not already a member of the group
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GroupScreen(groupSnapshot.id)),
        );
      } else {
        // Handle the case where the group with the provided code does not exist
        print('Group with code $groupCode does not exist');
      }
    } catch (e) {
      // Handle any errors that occur during the group joining process
      print('Error joining group: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if the user is already a member of any group upon initialization
    _checkUserGroupMembership();
  }

  Future<void> _checkUserGroupMembership() async {
    try {
      // Get the current user's ID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get a reference to the Firestore collection containing groups
      CollectionReference groupsCollection =
          FirebaseFirestore.instance.collection('groups');

      // Query Firestore to find any group where the user is a member
      QuerySnapshot querySnapshot =
          await groupsCollection.where('members', arrayContains: userId).get();

      // If the user is already a member of any group, navigate to the group screen
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot groupSnapshot = querySnapshot.docs.first;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GroupScreen(groupSnapshot.id)),
        );
      }
    } catch (e) {
      print('Error checking user group membership: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
      // Navigate back to the login screen after signing out
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        leading: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _logout(context);
            },
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _groupCodeController,
              decoration: const InputDecoration(labelText: 'Group Code'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              // Add TextFormField for entering username
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                String groupCode = _groupCodeController.text.trim();
                String username =
                    _usernameController.text.trim(); // Get entered username

                // Perform validation if needed
                if (groupCode.isEmpty || username.isEmpty) {
                  // Show an error message or handle invalid input
                  return;
                }

                // Call the joinGroup() function to join the group
                joinGroup(context, groupCode,
                    username); // Pass context and username to joinGroup
              },
              child: const Text('Join Group'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 50,
          child: Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupCreationScreen()),
                );
              },
              child: const Text(
                'Create Group',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: GroupJoinScreen(),
  ));
}
