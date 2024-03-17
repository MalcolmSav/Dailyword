import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_service.dart'; // Import your group_service.dart file
import 'word_submission.dart'; // Import the WordHintSubmissionScreen
import 'group_join_screen.dart'; // Import the GroupJoinScreen

class GroupScreen extends StatelessWidget {
  final String groupId;

  const GroupScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Group not found'),
            );
          }

          Map<String, dynamic> groupData =
              snapshot.data!.data() as Map<String, dynamic>;
          String groupName = groupData['groupName'];
          String groupCode = groupData['groupCode'];
          String creatorUsername = groupData['creatorUsername'];
          String creatorUID = groupData['creatorUID'];
          List<dynamic> members = groupData['members'] ?? [];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Group Name: $groupName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Group Code: $groupCode',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Creator Username: $creatorUsername',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Members: ${members.length}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Leaderboard:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      String username = members[index];
                      return ListTile(
                        title: Text(
                          username,
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: FutureBuilder<int>(
                          future: GroupService.getPointsForMember(username),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            return Text(
                              'Points: ${snapshot.data ?? 0}',
                              style: const TextStyle(fontSize: 16),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Call a function to leave the group
                    await _leaveGroup(context);
                  },
                  child: Text('Leave Group'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordHintSubmissionScreen(groupId),
                      ),
                    );
                  },
                  child: Text('Submit Word of the Day'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context) async {
    try {
      // Remove the current user from the group
      String username = FirebaseAuth.instance.currentUser!.displayName!;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([username]),
      });

      // Navigate back to the group join screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GroupJoinScreen(),
        ),
      );
    } catch (e) {
      print('Error leaving group: $e');
      // Handle error leaving group
    }
  }
}
