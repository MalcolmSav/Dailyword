// ignore_for_file: avoid_print

import 'package:dagensord/group_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  _GroupCreationScreenState createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Function to generate a random four-letter code
  String _generateGroupCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    String code = '';

    for (int i = 0; i < 4; i++) {
      int index = random.nextInt(letters.length);
      code += letters[index];
    }

    return code;
  }

  Future<void> _createGroup(String groupName, String groupCode, String username,
      String userId) async {
    try {
      // Get a reference to the Firestore collection containing groups
      CollectionReference groupsCollection =
          FirebaseFirestore.instance.collection('groups');

      // Create a new group document with initial data
      DocumentReference newGroupRef = await groupsCollection.add({
        'groupName': groupName,
        'groupCode': groupCode,
        'creatorUsername': username,
        'creatorUID': userId,
        'members': [userId],
      });

      // Create the 'word_hints' subcollection within the group document
      await newGroupRef.collection('word_hints').doc('hint').set({
        'dummy_field': 'dummy_value' // You can add any initial data if needed
      });

      // Create the 'leaderboard' subcollection within the group document
      // Here, we're assuming that each user starts with 0 points
      await newGroupRef.collection('leaderboard').doc(userId).set({
        'points': 0,
      });

      // Create the 'guesses' subcollection within the group document
      await newGroupRef.collection('guesses');

      // Join the group
      await _joinGroup(newGroupRef.id, userId, username);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created and joined!'),
        ),
      );

      // Navigate to the group screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupScreen(newGroupRef.id),
        ),
      );
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create group. Please try again.'),
        ),
      );
    }
  }

  Future<void> _joinGroup(
      String groupId, String userId, String username) async {
    try {
      // Get a reference to the Firestore collection containing groups
      CollectionReference groupsCollection =
          FirebaseFirestore.instance.collection('groups');

      // Update the group document to add the user as a member
      await groupsCollection.doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
        'current_word_submitter':
            userId, // Set current_word_submitter to the first member
      });
    } catch (e) {
      print('Error joining group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Your Username'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String groupName = _groupNameController.text.trim();
                String groupCode = _generateGroupCode();
                String username = _usernameController.text.trim();

                if (groupName.isEmpty || username.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Missing group name or username!'),
                    ),
                  );
                  return;
                }

                String userId = FirebaseAuth.instance.currentUser!.uid;

                await _createGroup(groupName, groupCode, username, userId);
              },
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
