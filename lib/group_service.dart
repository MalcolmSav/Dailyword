// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  static Future<int> getPointsForMember(String memberId) async {
    try {
      // Assuming you have a Firestore collection named 'users'
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      // Check if the user exists
      if (userSnapshot.exists) {
        // Access the user's data
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Assuming the user document has a field named 'points'
        int points =
            userData['points'] ?? 0; // Default to 0 if points field is null
        return points;
      } else {
        // Handle the case where the user does not exist
        return 0; // Return 0 points for non-existing user
      }
    } catch (e) {
      // Handle any errors that occur during the process
      print('Error getting points for member: $e');
      return 0; // Return 0 points if an error occurs
    }
  }
}
