import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_services.dart';
import '../../theme/toast_helper.dart';
import '../../widgets/custom_icon_widget.dart';
import '../home_screen/widgets/blog_post_card_widget.dart';

class MyBlogsScreen extends StatefulWidget {
  const MyBlogsScreen({super.key});

  @override
  State<MyBlogsScreen> createState() => _MyBlogsScreenState();
}

class _MyBlogsScreenState extends State<MyBlogsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _perPage = 6;

  DocumentSnapshot? _lastDocument;
  late ScrollController _scrollController;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _myBlogPosts = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _getCurrentUser();
    _fetchMyBlogPosts();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreBlogPosts();
    }
  }

  Map<String, dynamic> _mapPost(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'title': data['title'] ?? '',
      'author': data['author'] ?? '',
      'publishDate': _parseDate(data['publishDate']),
      'readingTime': data['readingTime'] ?? '',
      'category': data['category'] ?? '',
      'imageUrl': data['imageUrl'] ?? '',
      'excerpt': data['excerpt'] ?? '',
      'likes': data['likes'] ?? 0,
      'comments': data['comments'] ?? 0,
      'isBookmarked': false,
      'isPublished': data['isPublished'] ?? false,
      'content': data['content'] ?? '',
      'authorId': data['authorId'] ?? '',
    };
  }

  String _parseDate(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return '';
  }

  Future<void> _fetchMyBlogPosts() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
      _hasMore = true;
      _lastDocument = null;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('blog_posts')
          .where('authorId', isEqualTo: _currentUserId)
          .limit(_perPage);

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) => _mapPost(doc)).toList();

      // Sort by publish date (newest first)
      posts.sort((a, b) {
        final aDate = DateTime.tryParse(a['publishDate']) ?? DateTime.now();
        final bDate = DateTime.tryParse(b['publishDate']) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        _myBlogPosts = posts;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == _perPage;
      });
    } catch (e) {
      debugPrint("🔥 Error fetching my posts: $e");
      if (mounted) {
        ToastHelper.showError(context, 'Failed to fetch your blog posts');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMoreBlogPosts() async {
    if (!_hasMore ||
        _isLoadingMore ||
        _isLoading ||
        _lastDocument == null ||
        _currentUserId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('blog_posts')
          .where('authorId', isEqualTo: _currentUserId)
          .startAfterDocument(_lastDocument!)
          .limit(_perPage);

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) => _mapPost(doc)).toList();

      // Sort by publish date (newest first)
      posts.sort((a, b) {
        final aDate = DateTime.tryParse(a['publishDate']) ?? DateTime.now();
        final bDate = DateTime.tryParse(b['publishDate']) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        _myBlogPosts.addAll(posts);
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == _perPage;
      });
    } catch (e) {
      debugPrint("🔥 Error loading more posts: $e");
      if (mounted) {
        ToastHelper.showError(context, 'Failed to load more posts');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchMyBlogPosts();
  }

  Future<void> _deleteBlogPost(String postId, String postTitle) async {
    bool shouldDelete = await _showDeleteDialog(postTitle);
    if (!shouldDelete) return;

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await FirebaseFirestore.instance
          .collection('blog_posts')
          .doc(postId)
          .delete();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ToastHelper.showSuccess(context, 'Blog post deleted successfully');

        // Remove from local list
        setState(() {
          _myBlogPosts.removeWhere((post) => post['id'] == postId);
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ToastHelper.showError(
            context, 'Failed to delete blog post: ${e.toString()}');
      }
    }
  }

  Future<bool> _showDeleteDialog(String postTitle) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Delete Post',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Are you sure you want to delete this blog post?',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('"$postTitle"',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  const Text('This action cannot be undone.',
                      style: TextStyle(fontSize: 14, color: Colors.red)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _editBlogPost(Map<String, dynamic> post) {
    // Navigate to edit screen with post data
    Navigator.pushNamed(
      context,
      AppRoutes.editBlogsScreen,
      arguments: post,
    ).then((result) {
      // Refresh the list if post was edited
      if (result == true) {
        _fetchMyBlogPosts();
      }
    });
  }

  void _showPostActions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                _editBlogPost(post);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: post['isPublished'] ? 'visibility_off' : 'visibility',
                color: Colors.orange,
                size: 24,
              ),
              title: Text(post['isPublished'] ? 'Unpublish' : 'Publish'),
              onTap: () {
                Navigator.pop(context);
                _togglePublishStatus(post);
              },
            ),
            ListTile(
              leading: const CustomIconWidget(
                iconName: 'share',
                color: Colors.blue,
                size: 24,
              ),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const CustomIconWidget(
                iconName: 'delete',
                color: Colors.red,
                size: 24,
              ),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteBlogPost(post['id'], post['title']);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePublishStatus(Map<String, dynamic> post) async {
    try {
      final newStatus = !post['isPublished'];

      await FirebaseFirestore.instance
          .collection('blog_posts')
          .doc(post['id'])
          .update({'isPublished': newStatus});

      if (mounted) {
        setState(() {
          final index = _myBlogPosts.indexWhere((p) => p['id'] == post['id']);
          if (index != -1) {
            _myBlogPosts[index]['isPublished'] = newStatus;
          }
        });

        ToastHelper.showSuccess(
            context,
            newStatus
                ? 'Post published successfully'
                : 'Post unpublished successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to update post status');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blogs',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addBlogScreen)
                    .then((result) {
              if (result == true) {
                _fetchMyBlogPosts();
              }
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _myBlogPosts.isEmpty
                    ? _buildNoBlogPostsWidget()
                    : _buildMyBlogsView(),
              ),
      ),
    );
  }

  Widget _buildMyBlogsView() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: _myBlogPosts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _myBlogPosts.length) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        final post = _myBlogPosts[index];
        return _buildMyBlogPostCard(post);
      },
    );
  }

  Widget _buildMyBlogPostCard(Map<String, dynamic> post) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Status Banner
          if (!post['isPublished'])
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_off, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text('Draft',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          // Use the existing BlogPostCardWidget but add action buttons
          BlogPostCardWidget(
            post: post,
            onTap: () {
              // Navigate to post detail or edit
              _editBlogPost(post);
            },
            onLongPress: () => _showPostActions(context, post),
            onBookmarkTap: () {}, // Disable bookmark for own posts
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _editBlogPost(post),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteBlogPost(post['id'], post['title']),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showPostActions(context, post),
                    icon: const Icon(Icons.more_horiz, size: 18),
                    label: const Text('More'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBlogPostsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.create_outlined,
            size: 20.w,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Blog Posts Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start writing your first blog post!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addBlogScreen)
                    .then((result) {
              if (result == true) {
                _fetchMyBlogPosts();
              }
            }),
            icon: const Icon(Icons.add),
            label: const Text('Create New Post'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }
}
