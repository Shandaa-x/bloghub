import 'package:bloghub/presentation/home_screen/home_screen.dart';
import 'package:bloghub/presentation/location_screen/location_screen.dart';
import 'package:bloghub/presentation/profile_screen/profile_screen.dart';
import 'package:bloghub/presentation/qr_screen/qr_screen.dart';
import 'package:flutter/material.dart';

import '../../widgets/custom_icon_widget.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const QRScreen(),
    const LocationScreen(),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white, // Selected label color
        unselectedItemColor: Colors.white70, // Unselected label color
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'home', color: _navColor(0), size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'qr_code', color: _navColor(1), size: 24),
            label: 'Qr',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'location_on', color: _navColor(2), size: 24),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'person', color: _navColor(3), size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Color _navColor(int index) {
    return _currentIndex == index ? Colors.white : Colors.white70;
  }
}
