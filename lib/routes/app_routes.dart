import 'package:bloghub/auth/login_screen.dart';
import 'package:bloghub/presentation/add_blog_screen/add_blog_screen.dart';
import 'package:flutter/material.dart';
import '../auth/register_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/categories_screen/categories_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String categoriesScreen = '/categories-screen';
  static const String profileScreen = '/profile-screen';
  static const String registerScreen = '/register-screen';
  static const String addBlogScreen = '/add-blog-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    homeScreen: (context) => const HomeScreen(),
    categoriesScreen: (context) => const CategoriesScreen(),
    profileScreen: (context) => const ProfileScreen(),
    registerScreen: (context) => const RegisterScreen(),
    addBlogScreen: (context) => const AddBlogScreen(),
    // TODO: Add your other routes here
  };
}
