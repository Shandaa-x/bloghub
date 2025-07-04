import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/category_card_widget.dart';
import './widgets/category_search_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  int _selectedIndex = 1; // Categories tab selected
  String _searchQuery = '';
  bool _isSearching = false;

  // Mock data for categories
  final List<Map<String, dynamic>> _allCategories = [
    {
      "id": 1,
      "name": "Technology",
      "icon": "computer",
      "postCount": 245,
      "color": 0xFF3B82F6,
      "isPopular": true,
      "isFollowing": false,
      "description": "Latest tech trends and innovations"
    },
    {
      "id": 2,
      "name": "Health & Fitness",
      "icon": "fitness_center",
      "postCount": 189,
      "color": 0xFF10B981,
      "isPopular": true,
      "isFollowing": true,
      "description": "Wellness tips and fitness guides"
    },
    {
      "id": 3,
      "name": "Travel",
      "icon": "flight",
      "postCount": 156,
      "color": 0xFFF59E0B,
      "isPopular": true,
      "isFollowing": false,
      "description": "Explore destinations worldwide"
    },
    {
      "id": 4,
      "name": "Food & Cooking",
      "icon": "restaurant",
      "postCount": 134,
      "color": 0xFFEF4444,
      "isPopular": true,
      "isFollowing": true,
      "description": "Recipes and culinary adventures"
    },
    {
      "id": 5,
      "name": "Business",
      "icon": "business",
      "postCount": 98,
      "color": 0xFF8B5CF6,
      "isPopular": false,
      "isFollowing": false,
      "description": "Entrepreneurship and business insights"
    },
    {
      "id": 6,
      "name": "Lifestyle",
      "icon": "home",
      "postCount": 87,
      "color": 0xFFEC4899,
      "isPopular": false,
      "isFollowing": true,
      "description": "Life tips and personal development"
    },
    {
      "id": 7,
      "name": "Science",
      "icon": "science",
      "postCount": 76,
      "color": 0xFF06B6D4,
      "isPopular": false,
      "isFollowing": false,
      "description": "Scientific discoveries and research"
    },
    {
      "id": 8,
      "name": "Sports",
      "icon": "sports_soccer",
      "postCount": 65,
      "color": 0xFF84CC16,
      "isPopular": false,
      "isFollowing": false,
      "description": "Sports news and analysis"
    },
    {
      "id": 9,
      "name": "Art & Design",
      "icon": "palette",
      "postCount": 54,
      "color": 0xFFF97316,
      "isPopular": false,
      "isFollowing": true,
      "description": "Creative inspiration and design trends"
    },
    {
      "id": 10,
      "name": "Education",
      "icon": "school",
      "postCount": 43,
      "color": 0xFF6366F1,
      "isPopular": false,
      "isFollowing": false,
      "description": "Learning resources and educational content"
    },
    {
      "id": 11,
      "name": "Entertainment",
      "icon": "movie",
      "postCount": 32,
      "color": 0xFFE11D48,
      "isPopular": false,
      "isFollowing": false,
      "description": "Movies, music, and entertainment news"
    },
    {
      "id": 12,
      "name": "Finance",
      "icon": "account_balance",
      "postCount": 0,
      "color": 0xFF64748B,
      "isPopular": false,
      "isFollowing": false,
      "description": "Coming Soon"
    }
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _allCategories;
    }
    return _allCategories
        .where((category) => (category["name"] as String)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Map<String, dynamic>> get _popularCategories {
    return _filteredCategories
        .where((category) => category["isPopular"] == true)
        .toList();
  }

  List<Map<String, dynamic>> get _otherCategories {
    return _filteredCategories
        .where((category) => category["isPopular"] == false)
        .toList()
      ..sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        // Simulate updated post counts
        for (var category in _allCategories) {
          if (category["postCount"] > 0) {
            category["postCount"] =
                category["postCount"] + (category["postCount"] * 0.1).round();
          }
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onCategoryTap(Map<String, dynamic> category) {
    // Navigate to filtered post list
    Navigator.pushNamed(context, '/home-screen');
  }

  void _onCategoryLongPress(Map<String, dynamic> category) {
    _showCategoryOptions(category);
  }

  void _showCategoryOptions(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              category["name"] as String,
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName:
                    category["isFollowing"] ? 'favorite' : 'favorite_border',
                color: category["isFollowing"]
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                category["isFollowing"] ? 'Unfollow' : 'Follow',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  category["isFollowing"] = !category["isFollowing"];
                });
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'star_border',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                'Add to Favorites',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category["name"]} added to favorites'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (category["postCount"] > 0)
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'trending_up',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                title: Text(
                  'View Trending Posts',
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/home-screen');
                },
              ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-screen');
        break;
      case 1:
        // Already on categories screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        title: _isSearching
            ? CategorySearchWidget(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : Text(
                'Categories',
                style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
              ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: CustomIconWidget(
              iconName: _isSearching ? 'close' : 'search',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            if (_popularCategories.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Popular Categories',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = _popularCategories[index];
                      return CategoryCardWidget(
                        category: category,
                        onTap: () => _onCategoryTap(category),
                        onLongPress: () => _onCategoryLongPress(category),
                      );
                    },
                    childCount: _popularCategories.length,
                  ),
                ),
              ),
            ],
            if (_otherCategories.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'All Categories',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = _otherCategories[index];
                      return CategoryCardWidget(
                        category: category,
                        onTap: () => _onCategoryTap(category),
                        onLongPress: () => _onCategoryLongPress(category),
                      );
                    },
                    childCount: _otherCategories.length,
                  ),
                ),
              ),
            ],
            if (_filteredCategories.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'search_off',
                        color: AppTheme.lightTheme.colorScheme.outline,
                        size: 64,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No categories found',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Try adjusting your search',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: 10.h),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: AppTheme.lightTheme.bottomNavigationBarTheme.type,
        backgroundColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.unselectedItemColor,
        elevation: AppTheme.lightTheme.bottomNavigationBarTheme.elevation,
        selectedLabelStyle:
            AppTheme.lightTheme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle:
            AppTheme.lightTheme.bottomNavigationBarTheme.unselectedLabelStyle,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _selectedIndex == 0
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'category',
              color: _selectedIndex == 1
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _selectedIndex == 2
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
