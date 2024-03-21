import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WordGuessScreen extends StatefulWidget {
  final String groupId;

  const WordGuessScreen(this.groupId, {Key? key}) : super(key: key);

  @override
  _WordGuessScreenState createState() => _WordGuessScreenState();
}

class _WordGuessScreenState extends State<WordGuessScreen> {
  late String _hint = '';
  late String _correctWord = ''; // Variable to store the correct word
  late String _guess = ''; // Variable to hold the user's guess

  @override
  void initState() {
    super.initState();
    _loadWordHint();
  }

  Future<void> _loadWordHint() async {
    try {
      final DocumentSnapshot hintSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('word_hints')
          .doc('hint') // Assuming the document ID is 'hint'
          .get();

      setState(() {
        _hint = hintSnapshot['hint'];
        _correctWord = hintSnapshot['word']; // Assign the correct word
      });
    } catch (e) {
      print('Error loading word hint: $e');
    }
  }

  Future<void> _submitGuess(String guess) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get the current date
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Query Firestore to check if the user has already submitted a guess for the current day
      QuerySnapshot guessQuerySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('guesses')
          .where('guesser', isEqualTo: userId)
          .where('submission_date', isEqualTo: today)
          .get();

      // Check if the user has already submitted a guess for the current day
      if (guessQuerySnapshot.docs.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have reached the maximum number of attempts for today.'),
          ),
        );
        return;
      }

      // Check if the guess is correct
      bool isCorrectGuess = guess.toLowerCase() == _correctWord.toLowerCase();

      // Get a reference to the leaderboard document
      DocumentReference leaderboardDocRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('leaderboard')
          .doc(userId);

      // Check if the leaderboard document exists
      final DocumentSnapshot leaderboardSnapshot =
          await leaderboardDocRef.get();

      if (!leaderboardSnapshot.exists) {
        // Create the leaderboard document with the user's UID as the document ID
        await leaderboardDocRef.set({
          'points': 0,
          'last_correct_guess_date': null, // Initialize last_correct_guess_date
        });
      }

      // Check if the guess is correct and has not been guessed before on the same day
      if (isCorrectGuess) {
        Timestamp? lastCorrectGuessDate =
            leaderboardSnapshot['last_correct_guess_date'];

        if (lastCorrectGuessDate == null ||
            lastCorrectGuessDate.toDate().isBefore(today)) {
          // Increment the points for the user if the guess is correct and it's the first correct guess of the day
          await leaderboardDocRef.update({
            'points': FieldValue.increment(1),
            'last_correct_guess_date': Timestamp.fromDate(today),
          });
        } else {
          // Show a message if the user has already guessed correctly today
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('You have already submitted a correct guess today.'),
            ),
          );
          return;
        }
      }

      // Add the guess to Firestore
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('guesses')
          .add({
        'guesser': userId,
        'guess': guess,
        'submission_date': today,
        'is_correct': isCorrectGuess,
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        isCorrectGuess
            ? const SnackBar(
                content: Text('Congratulations! Your guess is correct!'),
              )
            : const SnackBar(
                content: Text('Sorry, your guess is incorrect.'),
              ),
      );
    } catch (e) {
      print('Error submitting guess: $e');
      // Show an error message if the guess submission fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit guess. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the Word'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hint: $_hint',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Your Guess'),
              onChanged: (value) {
                // Update the guess value as the user types
                _guess = value;
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Call the method to submit the guess when the button is pressed
                _submitGuess(_guess);
              },
              child: const Text('Guess'),
            ),
          ],
        ),
      ),
    );
  }
}
