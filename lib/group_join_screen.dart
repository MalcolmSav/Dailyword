// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'group_creation_screen.dart'; // Import the Main class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth
import 'group_screen.dart'; // Import the GroupScreen class

Future<void> joinGroup(BuildContext context, String groupCode) async {
  try {
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

      // Access the data of the group document
      Map<String, dynamic> groupData =
          groupSnapshot.data() as Map<String, dynamic>;

      // Access the groupName field from the group document
      String groupName = groupData[
          'groupName']; // Replace 'groupName' with the actual field name

      // Print the group name
      print('Group Name: $groupName');

      // Add current user to the group's members list
      await groupsCollection.doc(groupSnapshot.id).update({
        'members':
            FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
      });

      // Navigate to the group screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GroupScreen(groupSnapshot.id)),
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

class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  _GroupJoinScreenState createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final TextEditingController _groupCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
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
            ElevatedButton(
              onPressed: () {
                String groupCode = _groupCodeController.text.trim();

                // Perform validation if needed
                if (groupCode.isEmpty) {
                  // Show an error message or handle invalid input
                  return;
                }

                // Call the joinGroup() function to join the group
                joinGroup(context, groupCode); // Pass context to joinGroup
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
