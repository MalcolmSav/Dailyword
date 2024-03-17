// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart'; // Import the AuthService class
import 'sign_in.dart'; // Import the password_reset_screen.dart file

class SignUpScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  SignUpScreen({Key? key}); // Add username controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                  labelText: 'Username'), // Add username field
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Get the email, password, and username from the text fields
                final String email = emailController.text.trim();
                final String password = passwordController.text.trim();
                final String username =
                    usernameController.text.trim(); // Get username

                // Call the registerWithEmailAndPassword method from AuthService
                final AuthService authService = AuthService();
                final User? user =
                    await authService.registerWithEmailAndPassword(
                        email, password, username); // Pass username

                // Check if user registration was successful
                if (user != null) {
                  // Navigate to sign in screen after successful registration
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                } else {
                  // Registration failed, display an error message to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mail already in use mannen'),
                    ),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
