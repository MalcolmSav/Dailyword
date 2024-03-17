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

  String _generateGroupCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    String code = '';

    // Generate a random four-letter code
    for (int i = 0; i < 4; i++) {
      int index = random.nextInt(letters.length);
      code += letters[index];
    }

    return code;
  }

  Future<void> joinGroup(String groupId, String userId, String username) async {
    try {
      CollectionReference groupsCollection =
          FirebaseFirestore.instance.collection('groups');

      DocumentSnapshot groupSnapshot =
          await groupsCollection.doc(groupId).get();

      if (groupSnapshot.exists) {
        await groupsCollection.doc(groupId).update({
          'members': FieldValue.arrayUnion([userId]),
        });
      } else {
        print('Group with ID $groupId does not exist');
      }
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

                try {
                  String userId = FirebaseAuth.instance.currentUser!.uid;
                  DocumentReference newGroupRef = await FirebaseFirestore
                      .instance
                      .collection('groups')
                      .add({
                    'groupName': groupName,
                    'groupCode': groupCode,
                    'creatorUsername': username,
                    'creatorUID': userId,
                    'members': [userId],
                  });

                  await joinGroup(newGroupRef.id, userId, username);

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
                }
              },
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
