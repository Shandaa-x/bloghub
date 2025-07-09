import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BlogPostCardWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onBookmarkTap;

  const BlogPostCardWidget({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLongPress,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
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
            _buildPostHeader(context),
            _buildPostContent(context),
            _buildFeaturedImage(context),
            _buildEngagementStats(context),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: ClipOval(
              child: Image.network(
                'https://static.vecteezy.com/system/resources/previews/005/544/718/non_2x/profile-icon-design-free-vector.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['author'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      post['publishDate'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Text(
                      ' • ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Text(
                      post['readingTime'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Text(
                      ' • ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post['category'] as String,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLongPress,
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'more_horiz',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post['title'] as String,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            post['excerpt'] as String,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  height: 1.4,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFeaturedImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 25.h,
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: post['imageUrl'] as String,
              width: double.infinity,
              height: 25.h,
              fit: BoxFit.cover,
            ),
            // Positioned(
            //   top: 2.w,
            //   right: 2.w,
            //   child: GestureDetector(
            //     onTap: onBookmarkTap,
            //     child: Container(
            //       padding: EdgeInsets.all(2.w),
            //       decoration: BoxDecoration(
            //         color: Colors.black.withOpacity(0.6),
            //         shape: BoxShape.circle,
            //       ),
            //       child: CustomIconWidget(
            //         iconName: (post['isBookmarked'] as bool) ? 'bookmark' : 'bookmark_border',
            //         color: Colors.white,
            //         size: 18,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementStats(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          if (post['likes'] != null && post['likes'] > 0) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.thumb_up,
                    color: Colors.blue,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${post['likes']}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (post['comments'] != null && post['comments'] > 0) ...[
            Text(
              '${post['comments']} comments',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            SizedBox(width: 2.w),
          ],
          // Text(
          //   '${post['shares'] ?? 0} shares',
          //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
          //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(post['content']),
      // child: Row(
      //   children: [
      //     Expanded(
      //       child: _buildActionButton(
      //         context,
      //         icon: (post['isLiked'] as bool? ?? false) ? 'favorite' : 'favorite_border',
      //         label: 'Like',
      //         color: (post['isLiked'] as bool? ?? false) ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      //         onTap: () => _handleLike(),
      //       ),
      //     ),
      //     Expanded(
      //       child: _buildActionButton(
      //         context,
      //         icon: 'chat_bubble_outline',
      //         label: 'Comment',
      //         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      //         onTap: () => _handleComment(),
      //       ),
      //     ),
      //     Expanded(
      //       child: _buildActionButton(
      //         context,
      //         icon: 'share',
      //         label: 'Share',
      //         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      //         onTap: () => _handleShare(),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: color,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike() {
    // Implement like functionality
    print('Like tapped for post: ${post['id']}');
  }

  void _handleComment() {
    // Implement comment functionality
    print('Comment tapped for post: ${post['id']}');
  }

  void _handleShare() {
    // Implement share functionality
    print('Share tapped for post: ${post['id']}');
  }
}
