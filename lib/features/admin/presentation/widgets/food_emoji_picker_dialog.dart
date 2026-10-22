import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FoodEmojiPickerDialog extends StatefulWidget {
  final String currentEmoji;

  const FoodEmojiPickerDialog({
    super.key,
    this.currentEmoji = '🍽️',
  });

  @override
  State<FoodEmojiPickerDialog> createState() => _FoodEmojiPickerDialogState();
}

class _FoodEmojiPickerDialogState extends State<FoodEmojiPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isOffline = false;

  // Curated local list of common food emojis for instant offline fallback
  static const List<Map<String, String>> _localFoodEmojis = [
    {'emoji': '🍚', 'name': 'Rice'},
    {'emoji': '🍱', 'name': 'Bento Box'},
    {'emoji': '🍡', 'name': 'Dango / Snack'},
    {'emoji': '🍝', 'name': 'Spaghetti / Pasta'},
    {'emoji': '🥤', 'name': 'Cup with Straw / Beverage'},
    {'emoji': '🍨', 'name': 'Ice Cream / Dessert'},
    {'emoji': '⭐', 'name': 'Special / Star'},
    {'emoji': '🍽️', 'name': 'Plate / Dish'},
    {'emoji': '🍔', 'name': 'Burger'},
    {'emoji': '🍕', 'name': 'Pizza'},
    {'emoji': '🍗', 'name': 'Poultry Leg / Fried Chicken'},
    {'emoji': '🥩', 'name': 'Meat / Steak'},
    {'emoji': '🍟', 'name': 'French Fries'},
    {'emoji': '🌭', 'name': 'Hotdog'},
    {'emoji': '🥪', 'name': 'Sandwich'},
    {'emoji': '🌮', 'name': 'Taco'},
    {'emoji': '🌯', 'name': 'Burrito'},
    {'emoji': '🥗', 'name': 'Green Salad'},
    {'emoji': '🍜', 'name': 'Steaming Bowl / Noodle'},
    {'emoji': '🍣', 'name': 'Sushi'},
    {'emoji': '🍤', 'name': 'Fried Shrimp / Tempura'},
    {'emoji': '🧋', 'name': 'Bubble Tea'},
    {'emoji': '☕', 'name': 'Hot Drink / Coffee'},
    {'emoji': '🧃', 'name': 'Beverage Box'},
    {'emoji': '🍩', 'name': 'Doughnut'},
    {'emoji': '🍰', 'name': 'Shortcake'},
    {'emoji': '🧁', 'name': 'Cupcake'},
    {'emoji': '🥧', 'name': 'Pie'},
    {'emoji': '🍫', 'name': 'Chocolate'},
    {'emoji': '🍿', 'name': 'Popcorn'},
  ];

  List<Map<String, String>> _displayedEmojis = _localFoodEmojis;

  @override
  void initState() {
    super.initState();
    _fetchOpenMojiFood();
  }

  Future<void> _fetchOpenMojiFood() async {
    // Attempt fetching OpenMoji API for food-drink category
    setState(() => _isLoading = true);
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(
        Uri.parse('https://openmoji.org/api/emojis.json?group=food-drink'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final String content = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(content);
        final List<Map<String, String>> fetched = [];
        for (var item in data) {
          if (item['emoji'] != null && item['annotation'] != null) {
            fetched.add({
              'emoji': item['emoji'].toString(),
              'name': item['annotation'].toString(),
            });
          }
        }
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _displayedEmojis = fetched;
            _isOffline = false;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Network failure or timeout -> fallback to local food emoji dataset
    }
    if (mounted) {
      setState(() {
        _displayedEmojis = _localFoodEmojis;
        _isOffline = true;
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _getFilteredEmojis() {
    if (_searchQuery.trim().isEmpty) {
      return _displayedEmojis;
    }
    final q = _searchQuery.toLowerCase();
    return _displayedEmojis.where((e) {
      final name = e['name']?.toLowerCase() ?? '';
      final emoji = e['emoji'] ?? '';
      return name.contains(q) || emoji.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredEmojis();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.fastfood, color: AppColors.brandRed),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Select Food Emoji Icon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isOffline)
            Tooltip(
              message: 'Offline Mode: Showing default food emojis',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.wifi_off, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search food emoji (e.g. rice, burger, drink)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🍽️',
                        style: TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No matching food emoji found',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context, '🍽️'),
                        icon: const Icon(Icons.restaurant, size: 18),
                        label: const Text('Use Default Plate (🍽️)'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final emoji = item['emoji'] ?? '🍽️';
                    final isSelected = widget.currentEmoji == emoji;

                    return Tooltip(
                      message: item['name'] ?? '',
                      child: InkWell(
                        onTap: () => Navigator.pop(context, emoji),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.goldenYellow.withValues(alpha: 0.3)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.goldenYellow
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldenYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, '🍽️'),
          icon: const Icon(Icons.restaurant, size: 16),
          label: const Text('Default Plate Icon'),
        ),
      ],
    );
  }
}
