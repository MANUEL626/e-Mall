import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;
  String _selectedCategory = 'all';
  String _query = '';

  final List<_Product> _products = const [
    _Product(name: 'Hass Avocado Pair', price: '\$4.50', category: 'eco'),
    _Product(name: 'Artisan Sourdough', price: '\$6.25', category: 'eggbakery'),
    _Product(name: 'Zesty Orange', price: '\$8.90', category: 'nutrition'),
    _Product(name: 'Tropical Fruit Medley', price: '\$12.00', category: 'liquids'),
  ];

  List<_Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'all' || product.category == _selectedCategory;
      final matchesQuery = _query.isEmpty ||
          product.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5ECE7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        const categories = ['all', 'eco', 'eggbakery', 'nutrition', 'liquids'];
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map(
                          (category) => ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                              setModalState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _toggleSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                const Text(
                  'e-Mall',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B4721),
                  ),
                ),
                IconButton(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filters',
                ),
              ],
            ),
            if (_showSearchField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF3E4D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFFF0DACB), Color(0xFFE8E8C8)]),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summer\nHarvest\nCollective', style: TextStyle(fontSize: 42, height: 1.1, fontWeight: FontWeight.w700, color: Color(0xFF2F1B10))),
                  SizedBox(height: 10),
                  Text('Directly from the fertile valley farms to your kitchen.', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Categories', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF2F1B10))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _CategoryChip(
                  label: 'all',
                  bg: const Color(0xFFE7D8CD),
                  selected: _selectedCategory == 'all',
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
                _CategoryChip(
                  label: 'eco',
                  bg: const Color(0xFFC4F3A7),
                  selected: _selectedCategory == 'eco',
                  onTap: () => setState(() => _selectedCategory = 'eco'),
                ),
                _CategoryChip(
                  label: 'eggbakery',
                  bg: const Color(0xFFF6E2CB),
                  selected: _selectedCategory == 'eggbakery',
                  onTap: () => setState(() => _selectedCategory = 'eggbakery'),
                ),
                _CategoryChip(
                  label: 'nutrition',
                  bg: const Color(0xFFF2D7C7),
                  selected: _selectedCategory == 'nutrition',
                  onTap: () => setState(() => _selectedCategory = 'nutrition'),
                ),
                _CategoryChip(
                  label: 'liquids',
                  bg: const Color(0xFFFCE3D2),
                  selected: _selectedCategory == 'liquids',
                  onTap: () => setState(() => _selectedCategory = 'liquids'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Curated Picks', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF2F1B10))),
            const SizedBox(height: 10),
            if (products.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No products match your search/filter.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              GridView.builder(
                itemCount: products.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.64,
                ),
                itemBuilder: (context, index) {
                  final item = products[index];
                  return _ProductCard(name: item.name, price: item.price);
                },
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Row(
                children: [
                  _CategoryChip(
                    label: 'local_shipping',
                    bg: Color(0xFFF26D21),
                    fg: Colors.white,
                    selected: false,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Free Friday Delivery\nAll orders over \$50 delivered every Friday.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Product {
  const _Product({
    required this.name,
    required this.price,
    required this.category,
  });

  final String name;
  final String price;
  final String category;
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.name, required this.price});

  final String name;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEDE0D8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFFC45A12), shape: BoxShape.circle),
                height: 36,
                width: 36,
                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(price, style: const TextStyle(color: Color(0xFF5D2F15), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.bg,
    this.fg = const Color(0xFF3F2413),
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: selected
              ? Border.all(color: const Color(0xFF7B4721), width: 1.4)
              : null,
        ),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
