import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_services.dart';
import '../../theme/toast_helper.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/blog_post_card_widget.dart';
import './widgets/category_chip_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isRefreshing = false;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final AuthService _authService = AuthService();

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _perPage = 6;

  late ScrollController _scrollController;
  bool _isHeaderVisible = true;

  List<Map<String, dynamic>> _blogPosts = [];

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
    };
  }

  final List<String> _categories = [
    'All',
    'Technology',
    'Lifestyle',
    'Design',
    'Business',
    'Health',
    'Finance'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchInitialBlogPosts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreBlogPosts();
    }
  }

  Future<void> _fetchInitialBlogPosts() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _lastDocument = null;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('blog_posts')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .limit(_perPage);

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) => _mapPost(doc)).toList();

      setState(() {
        _blogPosts = posts;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == _perPage;
      });
    } catch (e) {
      debugPrint("🔥 Error fetching postsssss: $e");
      if (mounted) {
        ToastHelper.showError(context, 'Failed to fetch blog posts');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMoreBlogPosts() async {
    if (!_hasMore || _isLoadingMore || _isLoading || _lastDocument == null)
      return;

    setState(() => _isLoadingMore = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('blog_posts')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_perPage);

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) => _mapPost(doc)).toList();

      setState(() {
        _blogPosts.addAll(posts);
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

  String _parseDate(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return '';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_selectedCategory == 'All') {
      return _blogPosts;
    }
    return _blogPosts
        .where((post) => post['category'] == _selectedCategory)
        .toList();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchInitialBlogPosts();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<bool> _onWillPop() async {
    bool shouldSignOut = await _showSignOutDialog();
    if (shouldSignOut) {
      await _handleSignOut();
      return false;
    }
    return false;
  }

  Future<bool> _showSignOutDialog() async {
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
                  Icon(Icons.logout, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('Sign Out',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              content: const Text(
                  'Are you sure you want to sign out of BlogHub?',
                  style: TextStyle(fontSize: 16)),
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
                  child: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        ToastHelper.showSuccess(context, 'Signed out successfully');
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login-screen', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to sign out: ${e.toString()}');
      }
    }
  }

  void _toggleBookmark(String postId) {
    setState(() {
      final index = _blogPosts.indexWhere((post) => post['id'] == postId);
      if (index != -1) {
        _blogPosts[index]['isBookmarked'] = !_blogPosts[index]['isBookmarked'];
      }
    });
  }

  void _showQuickActions(BuildContext context, Map<String, dynamic> post) {
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
                iconName: post['isBookmarked'] ? 'bookmark' : 'bookmark_border',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title:
                  Text(post['isBookmarked'] ? 'Remove Bookmark' : 'Bookmark'),
              onTap: () {
                _toggleBookmark(post['id']);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'share',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'watch_later',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24),
              title: const Text('Save for Later'),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).dividerColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'BlogHub',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: CustomIconWidget(
                          iconName: 'brightness_6',
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: CustomIconWidget(
                          iconName: 'menu',
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Category Chips
              Container(
                height: 6.h,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return CategoryChipWidget(
                      category: _categories[index],
                      isSelected: _selectedCategory == _categories[index],
                      onTap: () => setState(
                          () => _selectedCategory = _categories[index]),
                    );
                  },
                ),
              ),

              // Post list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _filteredPosts.isEmpty
                            ? _buildNoBlogPostsWidget()
                            : _buildFacebookStyleView(),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.addBlogScreen),
          child: CustomIconWidget(
              iconName: 'add',
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24),
        ),
      ),
    );
  }

  Widget _buildFacebookStyleView() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: _filteredPosts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredPosts.length) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        final post = _filteredPosts[index];
        return BlogPostCardWidget(
          post: post,
          onTap: () {},
          onLongPress: () => _showQuickActions(context, post),
          onBookmarkTap: () => _toggleBookmark(post['id']),
        );
      },
    );
  }

  Widget _buildNoBlogPostsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 20.w,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Blog Posts Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Pull down to refresh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
