import 'package:bloghub/presentation/home_screen/home_screen.dart';
import 'package:bloghub/presentation/profile_screen/profile_screen.dart';
import 'package:bloghub/presentation/qr_screen/qr_screen.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';

// Main Bottom Navigation Widget
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const QRScanScreen(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'home', color: _navColor(0), size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'qr_code', color: _navColor(1), size: 24),
            label: 'Qr',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'bookmark', color: _navColor(2), size: 24),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
                iconName: 'person', color: _navColor(3), size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Color _navColor(int index) {
    return _currentIndex == index
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  }
}
