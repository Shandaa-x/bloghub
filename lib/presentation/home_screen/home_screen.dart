import 'package:bloghub/presentation/home_screen/widgets/comment_post_card_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_services.dart';
import '../../theme/toast_helper.dart';
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
  final int _perPage = 5;

  late ScrollController _scrollController;

  List<Map<String, dynamic>> _blogPosts = [];

  Map<String, dynamic> _mapPost(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'type': 'blog',
      'title': data['title'] ?? '',
      'author': data['author'] ?? '',
      'publishDate': _parseDate(data['publishDate']),
      'readingTime': data['readingTime'] ?? '',
      'category': data['category'] ?? '',
      'content': data['content'] ?? '',
      'imageUrl': data['imageUrl'] ?? '',
      'excerpt': data['excerpt'] ?? '',
      'likes': data['likes'] ?? 0,
      'comments': data['comments'] ?? 0,
      'isBookmarked': false,
    };
  }

  Map<String, dynamic> _mapComment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'type': 'comment',
      'title': data['title'] ?? '',
      'author': data['author'] ?? '',
      'publishDate': _parseDate(data['publishDate']),
      'readingTime': data['readingTime'] ?? '',
      'category': data['category'] ?? '',
      'content': data['content'] ?? '',
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
    _fetchInitialFeedItems();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreBlogPosts();
    }
  }

  Future<void> _fetchInitialFeedItems() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _lastDocument = null;
    });

    try {
      final blogQuery = FirebaseFirestore.instance
          .collection('blog_posts')
          .where('isPublished', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .limit(_perPage);

      final commentQuery = FirebaseFirestore.instance
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(_perPage);

      final blogSnapshot = await blogQuery.get();
      final commentSnapshot = await commentQuery.get();

      final blogPosts = blogSnapshot.docs.map(_mapPost).toList();
      final comments = commentSnapshot.docs.map(_mapComment).toList();

      final allItems = [...blogPosts, ...comments];

      allItems.sort((a, b) =>
          (b['publishDate'] ?? b['createdAt'])
              .compareTo(a['publishDate'] ?? a['createdAt']));

      setState(() {
        _blogPosts = allItems;
        _lastDocument = blogSnapshot.docs.isNotEmpty
            ? blogSnapshot.docs.last
            : null; // You can store both blog and comment last docs for paging
        _hasMore = blogSnapshot.docs.length == _perPage ||
            commentSnapshot.docs.length == _perPage;
      });
    } catch (e) {
      debugPrint("🔥 Error fetching feed: $e");
      if (mounted) {
        ToastHelper.showError(context, 'Failed to fetch feed');
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

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),

              // Title
              Text(
                'Create New',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),

              // Add Blog ListTile
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'article',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Add Blog',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Create a new blog post',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: CustomIconWidget(
                  iconName: 'arrow_forward_ios',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushNamed(context, AppRoutes.addBlogScreen);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              SizedBox(height: 1.h),

              // Add Comment ListTile
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'comment',
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Add Comment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Write a comment on a post',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: CustomIconWidget(
                  iconName: 'arrow_forward_ios',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushNamed(context, AppRoutes.addComment);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredFeedItems {
    if (_selectedCategory == 'All') return _blogPosts;

    return _blogPosts.where((item) {
      return item['category'] == _selectedCategory;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchInitialFeedItems();
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
        Navigator.pushNamed(context, AppRoutes.initial);
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
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
                    // IconButton(
                    //   icon: CustomIconWidget(
                    //       iconName: 'brightness_6',
                    //       color: Theme.of(context).colorScheme.onSurface),
                    //   onPressed: () {},
                    // ),
                    IconButton(
                      icon: CustomIconWidget(
                          iconName: 'menu',
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _filteredFeedItems.isEmpty
                            ? _buildNoBlogPostsWidget()
                            : _buildFacebookStyleView(),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOptionsBottomSheet(context),
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
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredFeedItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredFeedItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = _filteredFeedItems[index];

        // 🟦 Blog Post
        if (item['type'] == 'blog') {
          return BlogPostCardWidget(
            post: item,
            onTap: () {},
            onLongPress: () => _showQuickActions(context, item),
            onBookmarkTap: () => _toggleBookmark(item['id']),
          );
        }

        // 🟨 Comment Post
        if (item['type'] == 'comment') {
          return CommentPostCardWidget(
            post: item,
            onTap: () {},
            onLongPress: () => _showQuickActions(context, item),
            onBookmarkTap: () => _toggleBookmark(item['id']),
          );
        }

        return const SizedBox.shrink();
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(height: 3.h),
          Text(
            'No Blog Posts Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Pull down to refresh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface,
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
