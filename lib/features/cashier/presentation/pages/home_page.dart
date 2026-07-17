import 'package:flutter/material.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/food_card.dart';
import '../widgets/order_summary_panel.dart';

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

  void _removeFoodFromCart(String foodId) {
    setState(() {
      _orderItems.removeWhere((item) => item['food']['id'] == foodId);
    });
  }

  void _clearOrder() {
    setState(() {
      _orderItems.clear();
    });
  }

  void _checkout() {
    // Mock checkout action
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text('The transaction has been processed (Mock).'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearOrder();
            },
            child: const Text('OK'),
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
          ? FloatingActionButton.extended(
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
              foregroundColor: Colors.black,
              icon: const Icon(Icons.shopping_cart),
              label: Text('${_orderItems.length} Items'),
            )
          : null,
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Order',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Select items for the customer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon:  Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
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
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
      return  Center(
        child: Text(
          'No food items found.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final foodIdsInCart = _orderItems.map((item) => item['food']['id'] as String).toSet();

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: displayedFoods.length,
      itemBuilder: (context, index) {
        final food = displayedFoods[index];
        final inCart = foodIdsInCart.contains(food['id']);
        return FoodCard(
          food: food,
          isInCart: inCart,
          onAdd: () => _addToOrder(food),
          onRemove: () => _removeFoodFromCart(food['id']),
        );
      },
    );
  }
}
