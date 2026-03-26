import 'package:flutter/material.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Wishlist')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final titles = ['Organic Flow Vase', 'Indigo Heritage Throw', 'Artisan Ebony Stool'];
          final subtitles = ['Hand-molded in Accra', 'Ethically dyed organic cotton', 'Single block carving technique'];
          final prices = ['\$124.00', '\$85.00', '\$340.00'];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFEEDFD5),
                ),
              ),
              title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(subtitles[index]),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(prices[index], style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text('Add'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
