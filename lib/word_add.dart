import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WordHintAddScreen extends StatefulWidget {
  final String groupId;

  const WordHintAddScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  _WordHintAddScreenState createState() => _WordHintAddScreenState();
}

class _WordHintAddScreenState extends State<WordHintAddScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();

  Future<void> _addWordAndHint(String word, String hint) async {
    try {
      // Get the current user's UID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get the current date
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Query Firestore to check if the user has already submitted a word for the current day
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('word_hints')
          .where('submitter', isEqualTo: userId)
          .where('submission_date', isEqualTo: today)
          .get();

      // Check if the user has already submitted a word for the current day
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already submitted a word for today.'),
          ),
        );
        return;
      }

      // Add the word and hint to Firestore
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('word_hints')
          .doc('hint')
          .set({
        'word': word,
        'hint': hint,
        'submitter': userId,
        'submission_date': today,
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word and hint submitted successfully!'),
        ),
      );
    } catch (e) {
      print('Error adding word and hint: $e');
      // Show an error message if the submission fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit word and hint. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word and Hint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _wordController,
              decoration: const InputDecoration(labelText: 'Word'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _hintController,
              decoration: const InputDecoration(labelText: 'Hint'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String word = _wordController.text.trim();
                String hint = _hintController.text.trim();

                if (word.isEmpty || hint.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both word and hint.'),
                    ),
                  );
                  return;
                }

                await _addWordAndHint(word, hint);
              },
              child: const Text('Submit Word and Hint'),
            ),
          ],
        ),
      ),
    );
  }
}
