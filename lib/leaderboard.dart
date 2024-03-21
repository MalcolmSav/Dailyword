import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  final String groupId;

  const LeaderboardScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Group not found'),
            );
          }

          Map<String, dynamic> groupData =
              snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> members = groupData['members'] ?? [];

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              String userId = members[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('leaderboard')
                    .doc(userId) // Use UID as document ID
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('Error: Unable to fetch member data');
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Error: Member data not found');
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final points = data['points'] as int?;
                  final username = data['username'] as String?;
                  if (points != null && username != null) {
                    return ListTile(
                      title: Text(
                        username,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Text(
                        'Points: $points',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  } else {
                    return const Text('Data not available');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
