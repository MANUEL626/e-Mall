import 'package:flutter/material.dart';

class NewFeedSearchPage extends StatefulWidget {
  const NewFeedSearchPage({super.key});

  @override
  State<NewFeedSearchPage> createState() => _NewFeedSearchPageState();
}

class _NewFeedSearchPageState extends State<NewFeedSearchPage> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _suggestions = const [
    'Ochre Earth Vase',
    'Indigo Heritage Throw',
    'Woven Sisal Basket',
    'Ceremonial Mask',
    'Organic Flow Vase',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final filtered = _suggestions
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Feeds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search artisan products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF3E4D9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No results found.'),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final title = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.auto_awesome),
                          title: Text(title),
                          onTap: () => Navigator.of(context).pop(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
