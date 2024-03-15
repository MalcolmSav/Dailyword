import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up.dart'; // Import the sign-up.dart file
import 'pass_reset.dart'; // Import the password_reset_screen.dart
import 'auth.dart'; // Import the AuthService class
import 'group_join_screen.dart'; // Import the Main class

class SignInScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Get the email and password from the text fields
                final String email = emailController.text.trim();
                final String password = passwordController.text.trim();

                // Call the signInWithEmailAndPassword method from AuthService
                final AuthService authService = AuthService();
                final User? user = await authService.signInWithEmailAndPassword(
                    email, password);

                // Check if sign-in was successful
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupJoinScreen()),
                  );
                } else {
                  // Sign-in failed, display an error message to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed to sign in. Please check your credentials and try again.'),
                    ),
                  );
                }
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to sign-up screen when "Sign Up" button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PasswordResetScreen()),
                );
              },
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
