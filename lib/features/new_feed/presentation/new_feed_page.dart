import 'package:flutter/material.dart';
import 'new_feed_search_page.dart';

class NewFeedPage extends StatefulWidget {
  const NewFeedPage({super.key});

  @override
  State<NewFeedPage> createState() => _NewFeedPageState();
}

class _NewFeedPageState extends State<NewFeedPage> {
  final PageController _pageController = PageController();
  final Set<int> _likedItems = <int>{};
  final Set<int> _addedItems = <int>{};

  final List<_FeedItem> _items = const [
    _FeedItem(
      title: 'Ochre Earth Vase',
      subtitle: 'Hand-thrown terracotta with organic matte glaze.',
      seller: 'Amina Ceramics',
      price: '₦24,500',
      colors: [Color(0xFF3B3127), Color(0xFF8C765F)],
    ),
    _FeedItem(
      title: 'Indigo Heritage Throw',
      subtitle: 'Ethically dyed cotton from artisan cooperatives.',
      seller: 'Kano Loom',
      price: '₦31,000',
      colors: [Color(0xFF1E314A), Color(0xFF4F7A8A)],
    ),
    _FeedItem(
      title: 'Woven Sisal Basket',
      subtitle: 'Lightweight handwoven storage and decor piece.',
      seller: 'Savanna Weave',
      price: '₦18,200',
      colors: [Color(0xFF6A4C2D), Color(0xFFB18857)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _FeedFullScreenItem(
                  item: item,
                  isLiked: _likedItems.contains(index),
                  isAdded: _addedItems.contains(index),
                  onLikeTap: () {
                    setState(() {
                      if (_likedItems.contains(index)) {
                        _likedItems.remove(index);
                      } else {
                        _likedItems.add(index);
                      }
                    });
                  },
                  onAddTap: () {
                    setState(() {
                      if (_addedItems.contains(index)) {
                        _addedItems.remove(index);
                      } else {
                        _addedItems.add(index);
                      }
                    });
                  },
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NewFeedSearchPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                        const Text(
                          'e-Mall',
                          style: TextStyle(
                            color: Color(0xFFF3D4BE),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.tune, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedFullScreenItem extends StatelessWidget {
  const _FeedFullScreenItem({
    required this.item,
    required this.isLiked,
    required this.isAdded,
    required this.onLikeTap,
    required this.onAddTap,
  });

  final _FeedItem item;
  final bool isLiked;
  final bool isAdded;
  final VoidCallback onLikeTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.colors,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.38),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 170,
          child: Column(
            children: [
              _ActionRoundButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'WISHLIST',
                bgColor: isLiked ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: isLiked ? Colors.white : Colors.white,
                onTap: onLikeTap,
              ),
              const SizedBox(height: 16),
              _ActionRoundButton(
                icon: Icons.shopping_cart,
                label: 'ADD',
                bgColor: isAdded ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: isAdded ? Colors.white : Colors.white,
                onTap: onAddTap,
              ),
              const SizedBox(height: 16),
              _ActionRoundButton(icon: Icons.share, label: ''),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 80,
          bottom: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD98652),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.seller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: Color(0xFFE3DCD7),
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.price,
                style: const TextStyle(
                  color: Color(0xFFF47A2B),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRoundButton extends StatelessWidget {
  const _ActionRoundButton({
    required this.icon,
    required this.label,
    this.bgColor = const Color(0x57FFFFFF),
    this.iconColor = Colors.white,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.title,
    required this.subtitle,
    required this.seller,
    required this.price,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String seller;
  final String price;
  final List<Color> colors;
}
