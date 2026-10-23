import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryIconItem {
  final String key;
  final String name;
  final IconData icon;
  final String category;

  const CategoryIconItem({
    required this.key,
    required this.name,
    required this.icon,
    this.category = 'Meals',
  });
}

const List<CategoryIconItem> kCategoryIcons = [
  // Meals
  CategoryIconItem(key: 'utensils', name: 'Meals / Utensils', icon: LucideIcons.utensils, category: 'Meals'),
  CategoryIconItem(key: 'utensils_crossed', name: 'Dining', icon: LucideIcons.utensils_crossed, category: 'Meals'),
  CategoryIconItem(key: 'cooking_pot', name: 'Rice / Cooking Pot', icon: LucideIcons.cooking_pot, category: 'Meals'),
  CategoryIconItem(key: 'soup', name: 'Soup / Broth', icon: LucideIcons.soup, category: 'Meals'),
  CategoryIconItem(key: 'drumstick', name: 'Chicken / Pastil', icon: LucideIcons.drumstick, category: 'Meals'),
  CategoryIconItem(key: 'beef', name: 'Beef / Sisig', icon: LucideIcons.beef, category: 'Meals'),
  CategoryIconItem(key: 'fish', name: 'Fish / Seafood', icon: LucideIcons.fish, category: 'Meals'),
  CategoryIconItem(key: 'egg_fried', name: 'Fried Egg / Silog', icon: LucideIcons.egg_fried, category: 'Meals'),
  CategoryIconItem(key: 'egg', name: 'Boiled Egg', icon: LucideIcons.egg, category: 'Meals'),
  CategoryIconItem(key: 'salad', name: 'Salad / Veggies', icon: LucideIcons.salad, category: 'Meals'),

  // Fast Food & Snacks
  CategoryIconItem(key: 'pizza', name: 'Pizza', icon: LucideIcons.pizza, category: 'Snacks'),
  CategoryIconItem(key: 'sandwich', name: 'Sandwich / Burger', icon: LucideIcons.sandwich, category: 'Snacks'),
  CategoryIconItem(key: 'popcorn', name: 'Popcorn / Finger Food', icon: LucideIcons.popcorn, category: 'Snacks'),
  CategoryIconItem(key: 'croissant', name: 'Bakery / Bread', icon: LucideIcons.croissant, category: 'Snacks'),
  CategoryIconItem(key: 'apple', name: 'Fruit', icon: LucideIcons.apple, category: 'Snacks'),

  // Beverages
  CategoryIconItem(key: 'coffee', name: 'Coffee / Hot Drinks', icon: LucideIcons.coffee, category: 'Beverages'),
  CategoryIconItem(key: 'cup_soda', name: 'Soda / Cold Drinks', icon: LucideIcons.cup_soda, category: 'Beverages'),
  CategoryIconItem(key: 'beer', name: 'Cold Beverage', icon: LucideIcons.beer, category: 'Beverages'),
  CategoryIconItem(key: 'wine', name: 'Wine / Juice', icon: LucideIcons.wine, category: 'Beverages'),

  // Desserts
  CategoryIconItem(key: 'ice_cream_cone', name: 'Ice Cream', icon: LucideIcons.ice_cream_cone, category: 'Desserts'),
  CategoryIconItem(key: 'cake_slice', name: 'Cake / Pastry', icon: LucideIcons.cake_slice, category: 'Desserts'),
  CategoryIconItem(key: 'cookie', name: 'Cookies', icon: LucideIcons.cookie, category: 'Desserts'),
  CategoryIconItem(key: 'candy', name: 'Sweets', icon: LucideIcons.candy, category: 'Desserts'),

  // Specials & General
  CategoryIconItem(key: 'flame', name: 'Spicy / Hot Promo', icon: LucideIcons.flame, category: 'Specials'),
  CategoryIconItem(key: 'star', name: 'Favorites / Bestseller', icon: LucideIcons.star, category: 'Specials'),
  CategoryIconItem(key: 'sparkles', name: 'Specialty Items', icon: LucideIcons.sparkles, category: 'Specials'),
  CategoryIconItem(key: 'store', name: 'Store Specials', icon: LucideIcons.store, category: 'Specials'),
  CategoryIconItem(key: 'package', name: 'Combo Meals', icon: LucideIcons.package, category: 'Specials'),
  CategoryIconItem(key: 'heart', name: 'Chef Special', icon: LucideIcons.heart, category: 'Specials'),
];

final Map<String, IconData> kCategoryIconMap = {
  for (final item in kCategoryIcons) item.key: item.icon,
  // Common aliases
  'rice': LucideIcons.cooking_pot,
  'pastil': LucideIcons.drumstick,
  'chicken': LucideIcons.drumstick,
  'silog': LucideIcons.egg_fried,
  'drinks': LucideIcons.cup_soda,
  'drink': LucideIcons.cup_soda,
  'beverage': LucideIcons.coffee,
  'beverages': LucideIcons.cup_soda,
  'dessert': LucideIcons.cake_slice,
  'desserts': LucideIcons.cake_slice,
  'snack': LucideIcons.sandwich,
  'snacks': LucideIcons.sandwich,
  'pasta': LucideIcons.utensils,
  'noodles': LucideIcons.soup,
  'special': LucideIcons.star,
  'specials': LucideIcons.star,
};

Widget buildCategoryIconWidget(
  String? iconKeyOrEmoji, {
  double size = 18,
  Color? color,
}) {
  if (iconKeyOrEmoji == null || iconKeyOrEmoji.isEmpty) {
    return Icon(LucideIcons.utensils, size: size, color: color ?? AppColors.darkCharcoal);
  }
  
  final lower = iconKeyOrEmoji.toLowerCase().trim();
  final mappedIcon = kCategoryIconMap[lower];
  if (mappedIcon != null) {
    return Icon(mappedIcon, size: size, color: color ?? AppColors.darkCharcoal);
  }

  // If it's an emoji (contains non-ascii or emoji surrogate)
  if (iconKeyOrEmoji.runes.any((r) => r > 127)) {
    return Text(
      iconKeyOrEmoji,
      style: TextStyle(fontSize: size),
    );
  }

  return Icon(LucideIcons.utensils, size: size, color: color ?? AppColors.darkCharcoal);
}

class FoodIconPickerDialog extends StatefulWidget {
  final String currentIcon;

  const FoodIconPickerDialog({
    super.key,
    this.currentIcon = 'utensils',
  });

  @override
  State<FoodIconPickerDialog> createState() => _FoodIconPickerDialogState();
}

class _FoodIconPickerDialogState extends State<FoodIconPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _tabs = [
    'All',
    'Meals',
    'Snacks',
    'Beverages',
    'Desserts',
    'Specials',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kCategoryIcons.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = item.name.toLowerCase().contains(q) || item.key.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      contentPadding: const EdgeInsets.all(20),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shapes, size: 20, color: AppColors.goldenYellow),
              SizedBox(width: 10),
              Text(
                'Choose Category Icon',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            splashRadius: 18,
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 440,
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(50),
              ],
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search icons (e.g. coffee, chicken, rice)...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldenYellow, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedCategory == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : AppColors.darkCharcoal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.goldenYellow,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.goldenYellow : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = tab);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Icons Grid
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching icons found',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isCurrent = item.key == widget.currentIcon.toLowerCase().trim();

                        return InkWell(
                          onTap: () => Navigator.pop(context, item.key),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFFFEF3C7) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.goldenYellow
                                    : const Color(0xFFE2E8F0),
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 26,
                                  color: isCurrent
                                      ? AppColors.darkCharcoal
                                      : const Color(0xFF334155),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    color: isCurrent
                                        ? AppColors.darkCharcoal
                                        : AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
