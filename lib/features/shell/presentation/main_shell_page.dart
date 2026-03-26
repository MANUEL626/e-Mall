import 'package:flutter/material.dart';

import '../../cart/presentation/cart_page.dart';
import '../../home/presentation/home_page.dart';
import '../../new_feed/presentation/new_feed_page.dart';
import '../../profile/presentation/me_page.dart';
import '../../wishlist/presentation/wishlist_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const NewFeedPage(),
      MePage(
        onOpenCart: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartPage()));
        },
        onOpenWishlist: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistPage()));
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFF7F0EB),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'New'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
