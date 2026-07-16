import 'package:flutter/material.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/food_card.dart';
import '../widgets/order_summary_panel.dart';
import '../../../shared/widgets/state_placeholders.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  String _selectedCategoryId = '1';
  String _searchQuery = '';
  final List<Map<String, dynamic>> _orderItems = [];

  void _addToOrder(Map<String, dynamic> food) {
    setState(() {
      final existingIndex = _orderItems.indexWhere(
        (item) => item['food']['id'] == food['id'],
      );
      if (existingIndex >= 0) {
        _orderItems[existingIndex]['quantity']++;
      } else {
        _orderItems.add({'food': food, 'quantity': 1});
      }
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      _orderItems[index]['quantity']++;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (_orderItems[index]['quantity'] > 1) {
        _orderItems[index]['quantity']--;
      } else {
        _orderItems.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  void _clearOrder() {
    setState(() {
      _orderItems.clear();
    });
  }

  void _checkout() {
    double subtotal = 0;
    for (var item in _orderItems) {
      subtotal += (item['food']['price'] as double) * (item['quantity'] as int);
    }
    double total = subtotal + subtotal * 0.12;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Order'),
        content: Text('Process this order of ₱${total.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearOrder();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                _buildCategories(),
                Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                Expanded(child: _buildFoodGrid(isMobile)),
              ],
            ),
          ),
          if (!isMobile)
             VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          if (!isMobile)
            OrderSummaryPanel(
              orderItems: _orderItems,
              onIncrease: _increaseQuantity,
              onDecrease: _decreaseQuantity,
              onRemove: _removeItem,
              onClear: _clearOrder,
              onCheckout: _checkout,
            ),
        ],
      ),
      floatingActionButton: isMobile
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        builder: (_, controller) => OrderSummaryPanel(
                          orderItems: _orderItems,
                          onIncrease: _increaseQuantity,
                          onDecrease: _decreaseQuantity,
                          onRemove: _removeItem,
                          onClear: _clearOrder,
                          onCheckout: () {
                            Navigator.pop(context);
                            _checkout();
                          },
                        ),
                      ),
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Cart'),
                ),
                if (_orderItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Badge(
                      label: Text('${_orderItems.length}'),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildTopBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Order',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Select items for the customer',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: MockData.categories.length,
        itemBuilder: (context, index) {
          final cat = MockData.categories[index];
          final isSelected = cat['id'] == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(cat['name']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategoryId = cat['id']);
              },
              selectedColor: cs.primary,
              backgroundColor: cs.surfaceContainerLow,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodGrid(bool isMobile) {
    // Filter foods
    var displayedFoods = MockData.foods.where((f) {
      bool matchesCat =
          _selectedCategoryId == '1' ||
          f['category'] ==
              MockData.categories.firstWhere(
                (c) => c['id'] == _selectedCategoryId,
              )['name'];
      bool matchesSearch = f['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCat && matchesSearch;
    }).toList();

    if (displayedFoods.isEmpty) {
      return StatePlaceholders.empty(
        message: 'No menu items match your search. Try a different category or search term.',
        icon: Icons.search_off,
        context: context,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: displayedFoods.length,
      itemBuilder: (context, index) {
        return FoodCard(
          food: displayedFoods[index],
          onAdd: () => _addToOrder(displayedFoods[index]),
        );
      },
    );
  }
}
