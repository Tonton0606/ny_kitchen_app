import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/food_card.dart';
import '../widgets/order_summary_panel.dart';
import '../../../../../core/database/repositories/food_repository.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  final FoodRepository _foodRepo = FoodRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _foods = [];
  bool _isLoading = true;

  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final List<Map<String, dynamic>> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await _foodRepo.getCategories();
    final foods = await _foodRepo.getAllFoodItems();
    if (!mounted) return;
    setState(() {
      _categories = [
        {'id': 'all', 'name': 'All Foods'},
        ...cats,
      ];
      _foods = foods;
      _isLoading = false;
    });
  }

  void _addToOrder(Map<String, dynamic> food) {
    setState(() {
      final existingIndex = _orderItems.indexWhere(
        (item) => item['food']['id'].toString() == food['id'].toString(),
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
      _orderItems.removeWhere((item) => item['food']['id'].toString() == foodId);
    });
  }

  void _clearOrder() {
    setState(() {
      _orderItems.clear();
    });
  }

  Future<void> _confirmClearOrder() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear current order?'),
        content: const Text(
          'All items in this order will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear order'),
          ),
        ],
      ),
    );

    if (shouldClear == true) _clearOrder();
  }

  Future<void> _checkout() async {
    final subtotal = _orderItems.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['food']['price'] as num?)?.toDouble() ?? 0.0) * (item['quantity'] as int),
    );
    // Let's assume price already includes tax or we aren't adding 12% in DB for this simple version.
    // We will just use subtotal as total for now.
    final total = subtotal;
    final itemCount = _orderItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    final completed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerRight,
        child: _CheckoutDialog(total: total, itemCount: itemCount),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );

    if (completed != true || !mounted) return;

    // Build the transaction items payload
    final List<Map<String, dynamic>> itemsForDb = _orderItems.map((item) {
      final food = item['food'];
      final price = (food['price'] as num).toDouble();
      final qty = item['quantity'] as int;
      return {
        'food_item_id': food['id'],
        'food_name': food['name'],
        'food_price': price,
        'quantity': qty,
        'subtotal': price * qty,
      };
    }).toList();

    try {
      await _transactionRepo.createTransaction(
        userId: 1, // Fallback dummy user for now
        totalAmount: total,
        discount: 0,
        paymentMethod: 'cash', // Hardcoded as cash for now based on UI
        items: itemsForDb,
      );

      if (!mounted) return;
      _clearOrder();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Payment complete. Order has been submitted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving order: $e'), backgroundColor: Colors.red),
      );
    }
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
              onClear: _confirmClearOrder,
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
                      onClear: _confirmClearOrder,
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
              label: Text(
                '${_orderItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))} Items',
              ),
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
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                  letterSpacing: -0.4,
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon: Icon(
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
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catId = cat['id'].toString();
          final isSelected = catId == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(cat['name']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategoryId = catId);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodGrid(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter foods
    var displayedFoods = _foods.where((f) {
      bool matchesCat =
          _selectedCategoryId == 'all' ||
          f['category_id'].toString() == _selectedCategoryId;
      bool matchesSearch = f['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      // Ensure only available foods are shown in POS. Check string 'available' vs int 1 based on DB schema.
      // SQLite stores string for availability. Wait, let me check the repository query.
      // Wait, food['availability'] == 'available' in DB? In database_helper, availability is TEXT.
      bool isAvailable = f['availability'] == 'available' || f['is_available'] == true || f['is_available'] == 1;
      return matchesCat && matchesSearch && isAvailable;
    }).toList();

    if (displayedFoods.isEmpty) {
      return Center(
        child: Text(
          'No food items found.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final foodIdsInCart = _orderItems
        .map((item) => item['food']['id'].toString())
        .toSet();

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
        final inCart = foodIdsInCart.contains(food['id'].toString());
        return FoodCard(
          food: food,
          isInCart: inCart,
          onAdd: () => _addToOrder(food),
          onRemove: () => _removeFoodFromCart(food['id'].toString()),
        );
      },
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog({required this.total, required this.itemCount});

  final double total;
  final int itemCount;

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _cashController = TextEditingController();
  String? _cashError;

  double? get _cashReceived => double.tryParse(_cashController.text.trim());

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _completeCheckout() {
    if (_cashReceived == null || _cashReceived! < widget.total) {
      setState(() => _cashError = 'Enter an amount that covers the total');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final change = (_cashReceived ?? 0) - widget.total;

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0.0, 420.0),
          height: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete checkout',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review and collect cash payment.',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      tooltip: 'Close checkout',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.softBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.creamBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.softBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.itemCount} ${widget.itemCount == 1 ? 'item' : 'items'} in this order',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'TOTAL DUE',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₱${widget.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.darkCharcoal,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cash payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _cashController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cash received',
                          prefixText: '₱ ',
                          errorText: _cashError,
                        ),
                        onChanged: (_) => setState(() => _cashError = null),
                        onSubmitted: (_) => _completeCheckout(),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: change > 0
                              ? AppColors.successSurface
                              : Colors.grey.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Change due',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                            Text(
                              '₱${change > 0 ? change.toStringAsFixed(2) : '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.softBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _completeCheckout,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: AppColors.darkCharcoal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Accept payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
