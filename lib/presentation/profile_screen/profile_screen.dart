import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/reading_stats_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2; // Profile tab index
  bool _isDarkMode = false;
  double _textSize = 16.0;
  bool _pushNotifications = true;
  bool _categoryNotifications = true;
  bool _readingReminders = false;
  String _selectedLanguage = 'English';
  String _readingMode = 'Comfortable';

  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Sarah Johnson",
    "username": "@sarahreads",
    "joinDate": "Joined March 2023",
    "avatar":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face",
    "totalPostsRead": 247,
    "readingStreak": 12,
    "favoriteCategories": 5,
    "timeSpentReading": "48h 32m"
  };

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian'
  ];
  final List<String> _readingModes = ['Comfortable', 'Compact', 'Spacious'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              ProfileHeaderWidget(
                userData: _userData,
                onEditPressed: _showEditProfileDialog,
              ),

              SizedBox(height: 3.h),

              // Reading Statistics
              ReadingStatsWidget(userData: _userData),

              SizedBox(height: 3.h),

              // Settings Sections
              _buildSettingsSections(),

              SizedBox(height: 3.h),

              // Logout Button
              _buildLogoutButton(),

              SizedBox(height: 10.h), // Bottom navigation space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      children: [
        // Reading Preferences
        SettingsSectionWidget(
          title: "Reading Preferences",
          children: [
            _buildTextSizeSlider(),
            _buildThemeSelector(),
            _buildReadingModeSelector(),
          ],
        ),

        SizedBox(height: 2.h),

        // Notifications
        SettingsSectionWidget(
          title: "Notifications",
          children: [
            _buildSwitchTile(
              title: "Push Notifications",
              subtitle: "Get notified about new posts",
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
              icon: 'notifications',
            ),
            _buildSwitchTile(
              title: "Category Updates",
              subtitle: "Notifications for followed categories",
              value: _categoryNotifications,
              onChanged: (value) =>
                  setState(() => _categoryNotifications = value),
              icon: 'category',
            ),
            _buildSwitchTile(
              title: "Reading Reminders",
              subtitle: "Daily reading goal reminders",
              value: _readingReminders,
              onChanged: (value) => setState(() => _readingReminders = value),
              icon: 'schedule',
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Account
        SettingsSectionWidget(
          title: "Account",
          children: [
            _buildNavigationTile(
              title: "Edit Profile",
              subtitle: "Update your profile information",
              icon: 'edit',
              onTap: _showEditProfileDialog,
            ),
            _buildNavigationTile(
              title: "Change Password",
              subtitle: "Update your account password",
              icon: 'lock',
              onTap: _showChangePasswordDialog,
            ),
            _buildNavigationTile(
              title: "Export Data",
              subtitle: "Download your reading data",
              icon: 'download',
              onTap: _showExportDataDialog,
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // App Settings
        SettingsSectionWidget(
          title: "App Settings",
          children: [
            _buildLanguageSelector(),
            _buildNavigationTile(
              title: "Cache Management",
              subtitle: "Clear app cache (245 MB)",
              icon: 'storage',
              onTap: _showCacheManagementDialog,
            ),
            _buildNavigationTile(
              title: "Offline Storage",
              subtitle: "Manage downloaded content",
              icon: 'offline_pin',
              onTap: _showOfflineStorageDialog,
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // About
        SettingsSectionWidget(
          title: "About",
          children: [
            _buildNavigationTile(
              title: "App Version",
              subtitle: "BlogHub v1.2.3",
              icon: 'info',
              showArrow: false,
            ),
            _buildNavigationTile(
              title: "Privacy Policy",
              subtitle: "How we protect your data",
              icon: 'privacy_tip',
              onTap: _showPrivacyPolicy,
            ),
            _buildNavigationTile(
              title: "Terms of Service",
              subtitle: "App usage terms and conditions",
              icon: 'description',
              onTap: _showTermsOfService,
            ),
            _buildNavigationTile(
              title: "Send Feedback",
              subtitle: "Help us improve the app",
              icon: 'feedback',
              onTap: _showFeedbackDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextSizeSlider() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'text_fields',
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Text(
                "Text Size",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            "Preview: This is how your text will look",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _textSize,
                ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                "A",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Expanded(
                child: Slider(
                  value: _textSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  onChanged: (value) => setState(() => _textSize = value),
                ),
              ),
              Text(
                "A",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'palette',
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Text(
                "Theme",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildThemeOption("Light", !_isDarkMode,
                  () => setState(() => _isDarkMode = false)),
              SizedBox(width: 4.w),
              _buildThemeOption("Dark", _isDarkMode,
                  () => setState(() => _isDarkMode = true)),
              SizedBox(width: 4.w),
              _buildThemeOption("Auto", false, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingModeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'view_comfortable',
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reading Mode",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _readingMode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'chevron_right',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return GestureDetector(
      onTap: _showLanguageSelector,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'language',
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Language",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _selectedLanguage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required String icon,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              CustomIconWidget(
                iconName: 'chevron_right',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          padding: EdgeInsets.symmetric(vertical: 2.h),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              "Logout",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Profile"),
        content:
            Text("Profile editing functionality would be implemented here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password"),
        content:
            Text("Password change functionality would be implemented here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Export Data"),
        content: Text("Your reading data will be exported as a JSON file."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Export"),
          ),
        ],
      ),
    );
  }

  void _showCacheManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Cache"),
        content: Text("This will clear 245 MB of cached data. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _showOfflineStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Offline Storage"),
        content: Text("Manage your downloaded articles and offline content."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Privacy Policy"),
        content: Text("Privacy policy content would be displayed here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Terms of Service"),
        content: Text("Terms of service content would be displayed here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Send Feedback"),
        content: Text("Feedback form would be implemented here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Send"),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages
              .map((language) => ListTile(
                    title: Text(language),
                    leading: Radio<String>(
                      value: language,
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                        Navigator.pop(context);
                      },
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement logout logic here
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }
}
