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
  bool _isOrderPanelExpanded = true;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Void current order?'),
        content: const Text(
          'All items in this order will be voided and removed. ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Void order'),
          ),
        ],
      ),
    );

    if (shouldClear == true) _clearOrder();
  }

  Future<bool?> _showOrderReviewDialog({
    required double total,
    required int itemCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _OrderReviewDialog(
        orderItems: _orderItems,
        total: total,
        itemCount: itemCount,
      ),
    );
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

    final reviewed = await _showOrderReviewDialog(
      total: total,
      itemCount: itemCount,
    );

    if (reviewed != true || !mounted) return;

    final paymentResult = await showGeneralDialog<Map<String, double>?>(
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

    if (paymentResult == null || !mounted) return;
    final amountReceived = paymentResult['amountReceived']!;
    final change = paymentResult['change']!;

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
        userId: 1,
        totalAmount: total,
        discount: 0,
        paymentMethod: 'cash',
        amountReceived: amountReceived,
        change: change,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: _isOrderPanelExpanded ? 350 : 40,
              decoration: _isOrderPanelExpanded
                  ? BoxDecoration(
                      color: const Color(0xFFF8F6F0),
                      border: Border(
                        left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    )
                  : BoxDecoration(
                      color: const Color(0xFFF8F6F0),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(-3, 0),
                        ),
                      ],
                    ),
              child: _isOrderPanelExpanded
                  ? OrderSummaryPanel(
                      orderItems: _orderItems,
                      onIncrease: _increaseQuantity,
                      onDecrease: _decreaseQuantity,
                      onRemove: _removeItem,
                      onClear: _confirmClearOrder,
                      onCheckout: _checkout,
                      onCollapse: () => setState(() => _isOrderPanelExpanded = false),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _isOrderPanelExpanded = true),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 20, color: AppColors.darkCharcoal),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.goldenYellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_orderItems.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Icon(Icons.chevron_left, size: 14, color: AppColors.mutedText),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: _categories.map((cat) {
          final catId = cat['id'].toString();
          final isSelected = catId == _selectedCategoryId;
          return ChoiceChip(
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
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
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

    final isWide = !isMobile && !_isOrderPanelExpanded;

    return GridView.builder(
      padding: EdgeInsets.all(isWide ? 20 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : (isWide ? 4 : 3),
        childAspectRatio: isWide ? 1.1 : 0.8,
        crossAxisSpacing: isWide ? 12 : 16,
        mainAxisSpacing: isWide ? 14 : 16,
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

class _OrderReviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems;
  final double total;
  final int itemCount;

  const _OrderReviewDialog({
    required this.orderItems,
    required this.total,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.checklist, color: AppColors.brandRed),
          SizedBox(width: 10),
          Text(
            'Confirm Order',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(0.0, 440.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.brandRed, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Is this order correct? Please confirm with the customer before proceeding.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      child: Column(
                        children: orderItems.map((item) {
                          final food = item['food'];
                          final qty = item['quantity'] as int;
                          final price = (food['price'] as num).toDouble();
                          final subtotal = price * qty;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text(
                                  '$qty × ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    food['name'] ?? '',
                                    style: const TextStyle(color: AppColors.darkCharcoal),
                                  ),
                                ),
                                Text(
                                  '₱${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Go Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Confirm & Proceed'),
        ),
      ],
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
    Navigator.pop(context, {
      'amountReceived': _cashReceived!,
      'change': _cashReceived! - widget.total,
    });
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
                      onPressed: () => Navigator.pop(context, null),
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
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: change > 0
                              ? AppColors.brandRed.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: change > 0
                                ? AppColors.brandRed.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                  color: change > 0 ? AppColors.brandRed : AppColors.mutedText,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Change due',
                                  style: TextStyle(color: AppColors.mutedText),
                                ),
                              ],
                            ),
                            Text(
                              '₱${change > 0 ? change.toStringAsFixed(2) : '0.00'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: change > 0 ? AppColors.brandRed : AppColors.darkCharcoal,
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
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mutedText,
                          side: BorderSide(color: AppColors.softBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Accept payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
