// Create or update: lib/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'BlogHub',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Check for errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Authentication Error'),
                  SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to reload the app
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is logged in, navigate based on your routes
        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated - navigate to home
          return Scaffold(
            appBar: AppBar(title: Text('Home')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome ${snapshot.data!.email}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is not authenticated - show login
        return Scaffold(
          appBar: AppBar(title: Text('Login')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BlogHub',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                Text('Please log in to continue'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to your login screen
                    Navigator.of(context).pushNamed('/login-screen');
                  },
                  child: Text('Go to Login'),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Navigate to your register screen
                    Navigator.of(context).pushNamed('/register-screen');
                  },
                  child: Text('Create Account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}