import 'package:bloghub/auth/login_screen.dart';
import 'package:bloghub/presentation/add_blog_screen/add_blog_screen.dart';
import 'package:bloghub/presentation/add_blog_screen/add_comment_screen.dart';
import 'package:bloghub/presentation/bottom_nav/bottom_nav.dart';
import 'package:bloghub/presentation/edit_blog_screen/edit_blog_screen.dart';
import 'package:bloghub/presentation/my_blogs_screen/my_blogs_screen.dart';
import 'package:bloghub/presentation/qr_screen/qr_screen.dart';
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
  static const String bottomNav = '/bottom-nav';
  static const String myBlogsScreen = '/my-blogs-screen';
  static const String editBlogsScreen = '/edit-blogs-screen';
  static const String addComment = '/add-comment-screen';
  static const String qrScreen = '/qr-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    homeScreen: (context) => const HomeScreen(),
    categoriesScreen: (context) => const CategoriesScreen(),
    profileScreen: (context) => const ProfileScreen(),
    registerScreen: (context) => const RegisterScreen(),
    addBlogScreen: (context) => const AddBlogScreen(),
    bottomNav: (context) => const BottomNav(),
    myBlogsScreen: (context) => const MyBlogsScreen(),
    addComment: (context) => const AddCommentScreen(),
    qrScreen: (context) => const QRScanScreen(),
    editBlogsScreen: (context) {
      final post =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return EditBlogScreen(post: post);
    },
    // TODO: Add your other routes here
  };
}
