import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../theme/toast_helper.dart';
import '../../services/auth_services.dart';

class AddBlogScreen extends StatefulWidget {
  const AddBlogScreen({super.key});

  @override
  State<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _excerptController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String _selectedCategory = 'Technology';
  File? _selectedImage;
  String? _imageUrl;

  final List<String> _categories = ['Technology', 'Lifestyle', 'Design', 'Business', 'Health', 'Finance'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('📸 Starting image picker...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ Image selected: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      print('ℹ️ No image to upload');
      return null;
    }

    try {
      print('📤 Starting image upload...');

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String fileName = 'blog_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('📁 Upload path: $fileName');

      UploadTask uploadTask = _storage.ref().child(fileName).putFile(_selectedImage!);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('⬆️ Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  int _calculateReadingTime(String content) {
    // Average reading speed is 200 words per minute
    int wordCount = content.trim().split(RegExp(r'\s+')).length;
    int minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Future<void> _saveBlog() async {
    print('🚀 Starting blog save process...');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check authentication
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('👤 User authenticated: ${user.email}');

      // Get user data from Firestore
      print('📄 Fetching user data...');
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('⚠️ User document does not exist, creating basic profile...');
        // Create a basic user document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': user.displayName ?? 'Anonymous User',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'postsCount': 0,
        });
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String authorName = userData?['fullName'] ?? user.displayName ?? 'Anonymous';
      print('✅ Author name: $authorName');

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        print('📤 Uploading image...');
        imageUrl = await _uploadImage();
      } else {
        imageUrl = 'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3';
        print('🖼️ Using default image');
      }

      // Calculate reading time
      int readingTime = _calculateReadingTime(_contentController.text);
      print('⏱️ Reading time: $readingTime minutes');

      // Create blog post document
      print('📝 Creating blog post document...');
      DocumentReference blogRef = _firestore.collection('blog_posts').doc();

      Map<String, dynamic> blogData = {
        'id': blogRef.id,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'excerpt': _excerptController.text.trim(),
        'author': authorName,
        'authorId': user.uid,
        'authorEmail': user.email ?? '',
        'publishDate': DateTime.now().toIso8601String().split('T')[0],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'readingTime': '${readingTime} min read',
        'category': _selectedCategory,
        // 'imageUrl': imageUrl,
        'imageUrl': _urlController.text.trim(),
        'likes': 0,
        'comments': 0,
        'views': 0,
        'isPublished': true,
        'tags': [],
        'likedBy': [],
        'bookmarkedBy': [],
      };

      print('💾 Saving blog post to Firestore...');
      await blogRef.set(blogData);
      print('✅ Blog post saved with ID: ${blogRef.id}');

      // Update user's post count
      print('📊 Updating user post count...');
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'postsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User post count updated');
      } catch (e) {
        print('⚠️ Failed to update user post count: $e');
        // Don't fail the whole operation for this
      }

      // Update user stats (create if doesn't exist)
      print('📈 Updating user stats...');
      try {
        await _firestore.collection('user_stats').doc(user.uid).set({
          'uid': user.uid,
          'totalPosts': FieldValue.increment(1),
          'lastPostDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to create if doesn't exist
        print('✅ User stats updated');
      } catch (e) {
        print('⚠️ Failed to update user stats: $e');
        // Don't fail the whole operation for this
      }

      if (mounted) {
        print('🎉 Blog post published successfully!');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blog post published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _titleController.clear();
        _contentController.clear();
        _excerptController.clear();
        _urlController.clear();
        // setState(() {
        //   _selectedImage = null;
        //   _selectedCategory = 'Technology';
        // });

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Save blog error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Blog'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Using regular icon instead of CustomIconWidget
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBlog,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Publish',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image selection
                // Container(
                //   width: double.infinity,
                //   height: 25.h,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(
                //       color: Theme.of(context).dividerColor,
                //       width: 2,
                //     ),
                //   ),
                //   child:
                  // _selectedImage != null
                  //     ? ClipRRect(
                  //         borderRadius: BorderRadius.circular(10),
                  //         child: Stack(
                  //           children: [
                  //             Image.file(
                  //               _selectedImage!,
                  //               width: double.infinity,
                  //               height: double.infinity,
                  //               fit: BoxFit.cover,
                  //             ),
                  //             Positioned(
                  //               top: 8,
                  //               right: 8,
                  //               child: Container(
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.black54,
                  //                   shape: BoxShape.circle,
                  //                 ),
                  //                 child: IconButton(
                  //                   icon: Icon(Icons.close, color: Colors.white),
                  //                   onPressed: () {
                  //                     setState(() {
                  //                       _selectedImage = null;
                  //                     });
                  //                   },
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       )
                  //     : InkWell(
                  //         onTap: _pickImage,
                  //         borderRadius: BorderRadius.circular(10),
                  //         child: Container(
                  //           width: double.infinity,
                  //           height: double.infinity,
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(
                  //                 Icons.add_photo_alternate,
                  //                 size: 48,
                  //                 color: Theme.of(context).colorScheme.primary,
                  //               ),
                  //               SizedBox(height: 2.h),
                  //               Text(
                  //                 'Add Cover Image',
                  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //                       color: Theme.of(context).colorScheme.primary,
                  //                       fontWeight: FontWeight.w600,
                  //                     ),
                  //               ),
                  //               SizedBox(height: 1.h),
                  //               Text(
                  //                 'Tap to select from gallery',
                  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  //                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  //                     ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                // ),
                Text(
                  'Image url',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Enter an image url for your blog post',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    errorStyle: TextStyle(color: Colors.red),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image url';
                    }
                    if (value.trim().length < 10) {
                      return 'Url must be at least 10 characters long';
                    }
                    return null;
                  },
                ),

                // SizedBox(height: 2.h),

                SizedBox(height: 3.h),

                // Category selection
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),

                SizedBox(height: 2.h),

                // Title input
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter an engaging title for your blog post',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    errorStyle: TextStyle(color: Colors.red),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 10) {
                      return 'Title must be at least 10 characters long';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 2.h),

                // Excerpt input
                Text(
                  'Excerpt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _excerptController,
                  decoration: InputDecoration(
                    hintText: 'Write a brief description of your blog post',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    errorStyle: TextStyle(color: Colors.red),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an excerpt';
                    }
                    if (value.trim().length < 20) {
                      return 'Excerpt must be at least 20 characters long';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 2.h),

                // Content input
                Text(
                  'Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'Write your blog content here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    errorStyle: TextStyle(color: Colors.red),
                  ),
                  maxLines: 15,
                  minLines: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter blog content';
                    }
                    if (value.trim().length > 100) {
                      return 'Content must be at least 100 characters long';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 4.h),

                // Publish button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Publishing...',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          )
                        : Text(
                            'Publish Blog Post',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
