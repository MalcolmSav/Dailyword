import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordHintSubmissionScreen extends StatefulWidget {
  final String groupId;

  const WordHintSubmissionScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  _WordHintSubmissionScreenState createState() =>
      _WordHintSubmissionScreenState();
}

class _WordHintSubmissionScreenState extends State<WordHintSubmissionScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();

  Future<void> _submitWordAndHint() async {
    final String word = _wordController.text.trim();
    final String hint = _hintController.text.trim();

    if (word.isEmpty || hint.isEmpty) {
      // Show an error message if word or hint is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both the word and its hint.'),
        ),
      );
      return;
    }

    try {
      // Add the word and hint to Firestore
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('word_hints')
          .add({
        'word': word,
        'hint': hint,
        'submission_time': DateTime.now(),
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word and hint submitted successfully.'),
        ),
      );

      // Clear the text fields after submission
      _wordController.clear();
      _hintController.clear();
    } catch (e) {
      // Show an error message if submission fails
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
        title: const Text('Submit Word and Hint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
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
              onPressed: _submitWordAndHint,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
