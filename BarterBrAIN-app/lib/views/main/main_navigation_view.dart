import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';

import 'add_product_view.dart';
import 'chat_view.dart';
import 'home_view.dart';
import 'profile_view.dart';
import 'search_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _selectedIndex = 0;

  final _pages = [
    const HomeView(),
    const SearchView(),
    const AddProductView(),
    const ChatView(),
    ProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          _pages[_selectedIndex],
          // Native iOS Liquid Glass Tab Bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CNTabBar(
              items: const [
                CNTabBarItem(
                  label: 'Home',
                  icon: CNSymbol('house.fill'),
                ),
                CNTabBarItem(
                  label: 'Search',
                  icon: CNSymbol('magnifyingglass'),
                ),
                CNTabBarItem(
                  label: 'Add',
                  icon: CNSymbol('plus.circle.fill'),
                ),
                CNTabBarItem(
                  label: 'Chats',
                  icon: CNSymbol('message.fill'),
                ),
                CNTabBarItem(
                  label: 'Profile',
                  icon: CNSymbol('person.fill'),
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
