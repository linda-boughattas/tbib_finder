import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import 'chat_screen.dart';
import 'map_screen.dart';
import 'account_screen.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  int _bottomNavIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const ChatScreen(),
    const AccountScreen(),
  ];

  final List<String> _icons = [
    "assets/icons/map_icon.svg",
    "assets/icons/chat_icon.svg",
    "assets/icons/user_icon.svg",
  ];

  final List<String> _titles = ["Map", "Chat", "Account"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _bottomNavIndex, children: _screens),
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: 3,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none,
        backgroundColor: Colors.white,
        elevation: 10,
        leftCornerRadius: 20,
        rightCornerRadius: 20,
        splashColor: Colors.lightBlueAccent.withValues(alpha: 0.3),
        splashRadius: 18,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        tabBuilder: (int index, bool isActive) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                _icons[index],
                width: 24,
                height: 24,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              Gap(5),
              Text(
                _titles[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
