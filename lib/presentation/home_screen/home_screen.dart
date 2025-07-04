import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/blog_post_card_widget.dart';
import './widgets/category_chip_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isGridView = false;
  bool _isRefreshing = false;
  String _selectedCategory = 'All';
  late TabController _tabController;

  final List<Map<String, dynamic>> _blogPosts = [
    {
      "id": 1,
      "title": "The Future of Mobile Development: Flutter vs React Native",
      "author": "Sarah Johnson",
      "publishDate": "2024-01-15",
      "readingTime": "5 min read",
      "category": "Technology",
      "imageUrl":
          "https://images.unsplash.com/photo-1555066931-4365d14bab8c?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "excerpt":
          "Exploring the latest trends in cross-platform mobile development and what developers should know.",
      "likes": 124,
      "comments": 23,
      "isBookmarked": false,
    },
    {
      "id": 2,
      "title": "Sustainable Living: Small Changes, Big Impact",
      "author": "Michael Chen",
      "publishDate": "2024-01-14",
      "readingTime": "7 min read",
      "category": "Lifestyle",
      "imageUrl":
          "https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "excerpt":
          "Discover simple ways to reduce your environmental footprint and live more sustainably.",
      "likes": 89,
      "comments": 15,
      "isBookmarked": true,
    },
    {
      "id": 3,
      "title": "The Art of Minimalist Design in Modern Architecture",
      "author": "Emma Rodriguez",
      "publishDate": "2024-01-13",
      "readingTime": "6 min read",
      "category": "Design",
      "imageUrl":
          "https://images.pixabay.com/photo/2016/11/29/03/53/architecture-1867187_1280.jpg",
      "excerpt":
          "How minimalism is shaping contemporary architectural practices and urban planning.",
      "likes": 156,
      "comments": 31,
      "isBookmarked": false,
    },
    {
      "id": 4,
      "title": "Mastering Remote Work: Productivity Tips for Digital Nomads",
      "author": "David Kim",
      "publishDate": "2024-01-12",
      "readingTime": "8 min read",
      "category": "Business",
      "imageUrl":
          "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "excerpt":
          "Essential strategies for maintaining productivity while working from anywhere in the world.",
      "likes": 203,
      "comments": 45,
      "isBookmarked": true,
    },
    {
      "id": 5,
      "title": "The Science Behind Mindfulness and Mental Health",
      "author": "Dr. Lisa Thompson",
      "publishDate": "2024-01-11",
      "readingTime": "10 min read",
      "category": "Health",
      "imageUrl":
          "https://images.pexels.com/photos/3822622/pexels-photo-3822622.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "excerpt":
          "Research-backed insights into how mindfulness practices can improve mental well-being.",
      "likes": 178,
      "comments": 28,
      "isBookmarked": false,
    },
    {
      "id": 6,
      "title": "Cryptocurrency Trends: What to Watch in 2024",
      "author": "Alex Martinez",
      "publishDate": "2024-01-10",
      "readingTime": "9 min read",
      "category": "Finance",
      "imageUrl":
          "https://images.pixabay.com/photo/2017/12/12/12/44/bitcoin-3014614_1280.jpg",
      "excerpt":
          "An analysis of emerging cryptocurrency trends and their potential market impact.",
      "likes": 267,
      "comments": 52,
      "isBookmarked": false,
    },
  ];

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_selectedCategory == 'All') {
      return _blogPosts;
    }
    return _blogPosts
        .where((post) => (post['category'] as String) == _selectedCategory)
        .toList();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _toggleBookmark(int postId) {
    setState(() {
      final postIndex = _blogPosts.indexWhere((post) => post['id'] == postId);
      if (postIndex != -1) {
        _blogPosts[postIndex]['isBookmarked'] =
            !_blogPosts[postIndex]['isBookmarked'];
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
              title: Text(
                post['isBookmarked'] ? 'Remove Bookmark' : 'Bookmark',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                _toggleBookmark(post['id']);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Share',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Share functionality would be implemented here
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'watch_later',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Save for Later',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Save for later functionality would be implemented here
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  Text(
                    'BlogHub',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  // View toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: _isGridView ? 'view_list' : 'grid_view',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  // Theme toggle
                  IconButton(
                    onPressed: () {
                      // Theme toggle functionality would be implemented here
                    },
                    icon: CustomIconWidget(
                      iconName: 'brightness_6',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  // Menu
                  IconButton(
                    onPressed: () {
                      // Navigation drawer functionality would be implemented here
                    },
                    icon: CustomIconWidget(
                      iconName: 'menu',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Category chips
            Container(
              height: 6.h,
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return CategoryChipWidget(
                    category: _categories[index],
                    isSelected: _selectedCategory == _categories[index],
                    onTap: () {
                      setState(() {
                        _selectedCategory = _categories[index];
                      });
                    },
                  );
                },
              ),
            ),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _isGridView ? _buildGridView() : _buildListView(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              // Navigate to search (not implemented)
              break;
            case 2:
              // Navigate to bookmarks (not implemented)
              break;
            case 3:
              Navigator.pushNamed(context, '/profile-screen');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'search',
              color: _currentIndex == 1
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'bookmark',
              color: _currentIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 3
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/categories-screen');
        },
        child: CustomIconWidget(
          iconName: 'filter_list',
          color: Theme.of(context).colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return BlogPostCardWidget(
          post: post,
          isGridView: false,
          onTap: () {
            // Navigate to post detail (not implemented)
          },
          onLongPress: () {
            _showQuickActions(context, post);
          },
          onBookmarkTap: () {
            _toggleBookmark(post['id']);
          },
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return BlogPostCardWidget(
          post: post,
          isGridView: true,
          onTap: () {
            // Navigate to post detail (not implemented)
          },
          onLongPress: () {
            _showQuickActions(context, post);
          },
          onBookmarkTap: () {
            _toggleBookmark(post['id']);
          },
        );
      },
    );
  }
}
