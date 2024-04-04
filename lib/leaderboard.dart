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
              String username = members[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('leaderboard')
                    .doc(username)
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
                  int points = snapshot.data!['points'] ?? 0;
                  String username = snapshot.data!['username'] ?? 'Unknown';
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
                },
              );
            },
          );
        },
      ),
    );
  }
}
