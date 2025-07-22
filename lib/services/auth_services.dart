import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    UserCredential? userCredential;

    try {
      // Step 1: Create user with FirebaseAuth
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Step 2: Save user to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': user.email ?? '',
          'emailVerified': user.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ User saved to Firestore: ${user.uid}');
      } else {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'User was not returned after creation.',
        );
      }

      return userCredential;
    } catch (e) {
      print('❌ Error during registration: $e');

      // If the user was created in Auth but Firestore failed
      if (userCredential?.user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(userCredential!.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'fullName': fullName.trim(),
            'email': userCredential.user!.email ?? '',
            'emailVerified': userCredential.user!.emailVerified,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Firestore retry successful');
        } catch (retryError) {
          print('❌ Retry to save Firestore user failed: $retryError');
        }
      }

      rethrow;
    }
  }

  // Create comprehensive user document in Firestore
  Future<void> _createCompleteUserDocument(User user, String fullName) async {
    try {
      print('🔄 Creating Firestore document for user: ${user.uid}');

      // Comprehensive user  data
      final userData = {
        // Basic Information
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': user.email ?? '',
        'emailVerified': user.emailVerified,

        // Profile Information
        'displayName': fullName.trim(),
        'profilePicture': null,
        'bio': '',
        'dateOfBirth': null,
        'phoneNumber': user.phoneNumber,

        // Account Status
        'isActive': true,
        'accountType': 'regular', // regular, premium, admin
        'accountStatus': 'active', // active, suspended, pending

        // Blog Related
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'likesCount': 0,

        // Preferences
        'preferences': {
          'emailNotifications': true,
          'pushNotifications': true,
          'privacyLevel': 'public', // public, friends, private
          'theme': 'system', // light, dark, system
          'language': 'en',
        },

        // Social Links
        'socialLinks': {
          'website': null,
          'twitter': null,
          'instagram': null,
          'linkedin': null,
        },

        // Security & Verification
        'emailVerificationSent': false,
        'emailVerificationSentAt': null,
        'phoneVerified': false,
        'twoFactorEnabled': false,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),

        // Metadata
        'registrationMethod': 'email_password',
        'appVersion': '1.0.0',
        'platform': 'android', // or ios

        // Admin fields
        'isAdmin': false,
        'isModerator': false,
        'isBanned': false,
        'banReason': null,
        'banExpiresAt': null,
      };

      // Create the document
      await _firestore.collection('users').doc(user.uid).set(userData);
      print('✅ Complete user document created in Firestore');

      // Also create user stats document
      await _createUserStatsDocument(user.uid);
    } catch (e) {
      print('❌ Failed to create Firestore document: $e');
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Create user statistics document
  Future<void> _createUserStatsDocument(String uid) async {
    try {
      await _firestore.collection('user_stats').doc(uid).set({
        'uid': uid,
        'totalPosts': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'totalViews': 0,
        'totalShares': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'lastPostDate': null,
        'averagePostsPerMonth': 0.0,
        'engagementRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User stats document created');
    } catch (e) {
      print('⚠️ Failed to create user stats document: $e');
      // Don't throw error as this is not critical
    }
  }

  // Verify that the user document was actually created
  Future<void> _verifyUserDocumentCreated(String uid) async {
    try {
      print('🔄 Verifying user document creation...');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['uid'] == uid) {
          print('✅ User document verified in Firestore');
          print('📊 Document contains ${data.keys.length} fields');
        } else {
          throw Exception('User document exists but data is invalid');
        }
      } else {
        throw Exception('User document was not created in Firestore');
      }
    } catch (e) {
      print('❌ User document verification failed: $e');
      throw Exception(
          'Failed to verify user document creation: ${e.toString()}');
    }
  }

  // Perform optional operations that might fail due to PigeonUserDetails bug
  void _performOptionalOperations(User user, String fullName) {
    Future.microtask(() async {
      // Update display name
      await _updateDisplayNameSafely(user, fullName);

      // Send email verification
      await _sendEmailVerificationSafely(user);
    });
  }

  // Safely update display name
  Future<void> _updateDisplayNameSafely(User user, String fullName) async {
    try {
      await user.updateDisplayName(fullName);

      // Update Firestore to track success
      await _firestore.collection('users').doc(user.uid).update({
        'displayNameUpdated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Display name updated successfully');
    } catch (e) {
      print('⚠️ Display name update failed (non-critical): $e');

      // Update Firestore to track failure
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'displayNameUpdated': false,
          'displayNameError': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        print('Failed to update display name status: $firestoreError');
      }
    }
  }

  // Safely send email verification
  Future<void> _sendEmailVerificationSafely(User user) async {
    try {
      await user.sendEmailVerification();

      // Update Firestore to track success
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerificationSent': true,
        'emailVerificationSentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Email verification sent successfully');
    } catch (e) {
      print('⚠️ Email verification failed (non-critical): $e');

      // Update Firestore to track failure
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerificationSent': false,
          'emailVerificationError': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        print('Failed to update email verification status: $firestoreError');
      }
    }
  }

  // Get complete user data from Firestore
  Future<Map<String, dynamic>?> getCompleteUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Failed to get user data: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(updates);
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Failed to update user data: $e');
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login time
      if (userCredential.user != null) {
        _updateLastLoginSafely(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Safely update last login time
  void _updateLastLoginSafely(String uid) {
    Future.microtask(() async {
      try {
        await _firestore.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        print('✅ Last login updated');
      } catch (e) {
        print('⚠️ Failed to update last login (non-critical): $e');
      }
    });
  }

  // Sign out
  Future<void> signOut() async {
    try {
      String? uid = _auth.currentUser?.uid;
      await _auth.signOut();

      // Update last logout time
      if (uid != null) {
        try {
          await _firestore.collection('users').doc(uid).update({
            'lastLogoutAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('⚠️ Failed to update logout time: $e');
        }
      }
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      rethrow;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Send email verification manually
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await _sendEmailVerificationSafely(user);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Failed to reload user: $e');
    }
  }
}
