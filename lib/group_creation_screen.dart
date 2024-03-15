import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  _GroupCreationScreenState createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();

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
              decoration: const InputDecoration(labelText: 'Group Code'),
              readOnly: true,
              initialValue: _generateGroupCode(),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String groupName = _groupNameController.text.trim();
                String groupCode = _generateGroupCode();

                // Perform validation if needed
                if (groupName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Missing group name!'),
                    ),
                  );
                  return;
                }

                try {
                  // Save group data to Firestore
                  await FirebaseFirestore.instance.collection('groups').add({
                    'groupName': groupName,
                    'groupCode': groupCode,
                    // Add more properties as needed
                  });

                  // Navigate back after group creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group created!'),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  // Handle errors, e.g., display an error message
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
