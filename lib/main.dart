import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'firebase_options.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and test connection
  await initializeFirebase();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

/// Initialize Firebase and test the connection
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await testFirebaseConnection();
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
    // You can add more error handling here if needed
  }
}

/// Test Firebase connection
Future<void> testFirebaseConnection() async {
  try {
    // Check if Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      print("✅ Firebase connected successfully!");
      print("📱 App name: ${Firebase.app().name}");
      print("🔗 Project ID: ${Firebase.app().options.projectId}");

      // Optional: Test Firestore connection
      // Note: This will only work if you have proper Firestore rules set up
      // await FirebaseFirestore.instance.enableNetwork();
      // print("✅ Firestore connection successful!");

    } else {
      print("❌ Firebase apps list is empty");
    }
  } catch (e) {
    print("❌ Firebase connection test failed: $e");
    // Log the specific error for debugging
    debugPrint("Firebase connection error details: $e");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'bloghub',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}