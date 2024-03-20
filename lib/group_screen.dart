import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_service.dart'; // Import your group_service.dart file
import 'word_submission.dart'; // Import the WordHintSubmissionScreen
import 'group_join_screen.dart'; // Import the GroupJoinScreen
import 'leaderboard.dart'; // Import the LeaderboardScreen
import 'word_add.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late String _currentWordSubmitter;

  @override
  void initState() {
    super.initState();
    _getCurrentWordSubmitter();
  }

  Future<void> _getCurrentWordSubmitter() async {
    try {
      final DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      setState(() {
        _currentWordSubmitter = groupSnapshot['members']
            [0]; // Assuming the first member submits the word
      });
    } catch (e) {
      print('Error getting current word submitter: $e');
    }
  }

  Future<void> _submitWordAndHint(String word, String hint) async {
    if (_currentWordSubmitter != FirebaseAuth.instance.currentUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not authorized to submit the word.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('word_hints')
          .add({
        'word': word,
        'hint': hint,
        'submitter': _currentWordSubmitter,
        'submission_time': DateTime.now(),
      });

      // Update the current word submitter for the next day
      await _updateWordSubmitter();

      // Update the points for each member
      await _updatePoints();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word and hint submitted successfully.'),
        ),
      );
    } catch (e) {
      print('Error submitting word and hint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit word and hint. Please try again.'),
        ),
      );
    }
  }

  Future<void> _updatePoints() async {
    try {
      // Get a reference to the leaderboard collection
      CollectionReference leaderboardRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('leaderboard');

      // Get the members of the group
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      List<dynamic> members = List.from(groupSnapshot['members']);

      // Iterate over each member and update their points
      for (String member in members) {
        // Get the total number of word hints submitted by the member
        QuerySnapshot hintSnapshots = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('word_hints')
            .where('submitter', isEqualTo: member)
            .get();
        int points = hintSnapshots.docs.length;

        // Update the points in the leaderboard
        await leaderboardRef.doc(member).set({'points': points});
      }
    } catch (e) {
      print('Error updating points: $e');
    }
  }

  Future<void> _updateWordSubmitter() async {
    try {
      final DocumentReference groupRef =
          FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      await groupRef.update({
        'members': FieldValue.arrayRemove([_currentWordSubmitter]),
      });

      final DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final List<dynamic> members = List.from(groupSnapshot['members']);
      final String newSubmitter = members.isNotEmpty ? members[0] : '';

      await groupRef.update({
        'members': FieldValue.arrayUnion([_currentWordSubmitter]),
        'current_word_submitter': newSubmitter,
      });

      setState(() {
        _currentWordSubmitter = newSubmitter;
      });
    } catch (e) {
      print('Error updating word submitter: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
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
          List<dynamic> members = groupData['members'] ?? [];
          String wordSubmitter = groupData['current_word_submitter'] ?? '';

          print(
              'Current word submitter: $wordSubmitter'); // Add this line for debugging

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
                  'Members: ${members.length}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                if (wordSubmitter == FirebaseAuth.instance.currentUser!.uid &&
                    members.isNotEmpty &&
                    members[0] == FirebaseAuth.instance.currentUser!.uid)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WordHintAddScreen(widget.groupId),
                        ),
                      );
                    },
                    child: const Text('Submit Word of the Day'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordGuessScreen(widget.groupId),
                        ),
                      );
                    },
                    child: const Text('Guess Word'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardScreen(widget.groupId),
                      ),
                    );
                  },
                  child: const Text('View Leaderboard'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Call a function to leave the group
                    await _leaveGroup(context);
                  },
                  child: const Text('Leave Group'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshGroupData() async {
    try {
      // Call the method to get the current word submitter
      await _getCurrentWordSubmitter();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group data refreshed.'),
        ),
      );
    } catch (e) {
      print('Error refreshing group data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh group data. Please try again.'),
        ),
      );
    }
  }

  Future<void> _leaveGroup(BuildContext context) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference groupRef =
          FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      DocumentSnapshot groupSnapshot = await groupRef.get();
      List<dynamic> members = List.from(groupSnapshot['members']);

      // Check if the user is the last member of the group
      if (members.length == 1 && members.contains(userId)) {
        // If the user is the last member, delete the group document
        await groupRef.delete();
      } else {
        // If the user is not the last member, remove the user from the members list
        await groupRef.update({
          'members': FieldValue.arrayRemove([userId]),
        });
      }

      // Navigate back to the group join screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GroupJoinScreen(),
        ),
      );
    } catch (e) {
      print('Error leaving group: $e');
    }
  }
}
