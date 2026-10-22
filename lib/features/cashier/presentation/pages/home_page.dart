import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/food_card.dart';
import '../widgets/order_summary_panel.dart';
import '../../../../../core/database/repositories/food_repository.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../shared/widgets/manual_sync_button.dart';

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
  String _currentOrderId = _generateOrderId();

  static String _generateOrderId() =>
      DateTime.now().millisecondsSinceEpoch.toString().substring(6);

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
        (item) => item['food']['id'].toString() == food['id'].toString() && item['quantity'] < 50,
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
      if (_orderItems[index]['quantity'] < 50) {
        _orderItems[index]['quantity']++;
      } else {
        _orderItems.add({'food': _orderItems[index]['food'], 'quantity': 1});
      }
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
      _currentOrderId = _generateOrderId();
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

    final paymentResult = await showGeneralDialog<Map<String, dynamic>?>(
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
    final double amountReceived = paymentResult['amountReceived'] as double;
    final double change = paymentResult['change'] as double;
    final int? customOrderNumber = paymentResult['customOrderNumber'] as int?;

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
      final result = await _transactionRepo.createTransaction(
        userId: 1,
        totalAmount: total,
        discount: 0,
        paymentMethod: 'cash',
        amountReceived: amountReceived,
        change: change,
        items: itemsForDb,
        customOrderNumber: customOrderNumber,
      );

      if (!mounted) return;
      _clearOrder();
      
      final orderNumber = result['order_number'];
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Payment Complete!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Order has been submitted.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'ORDER #',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '$orderNumber',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Start Next Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
              width: _isOrderPanelExpanded ? 380 : 44,
              decoration: _isOrderPanelExpanded
                  ? BoxDecoration(
                      color: AppColors.surfaceWhite,
                      border: Border(
                        left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    )
                  : BoxDecoration(
                      color: AppColors.surfaceWhite,
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
                      orderId: _currentOrderId,
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
                      orderId: _currentOrderId,
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

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('all')) return LucideIcons.layout_grid;
    if (lower.contains('pastil')) return LucideIcons.utensils;
    if (lower.contains('silog')) return LucideIcons.egg_fried;
    if (lower.contains('drink') || lower.contains('beverage') || lower.contains('juice')) return LucideIcons.coffee;
    if (lower.contains('soup')) return LucideIcons.soup;
    if (lower.contains('side') || lower.contains('snack')) return LucideIcons.sandwich;
    if (lower.contains('dessert') || lower.contains('cake')) return LucideIcons.cake_slice;
    if (lower.contains('burger')) return LucideIcons.sandwich;
    if (lower.contains('pasta') || lower.contains('noodle')) return LucideIcons.cooking_pot;
    return LucideIcons.utensils;
  }

  int _getCategoryItemCount(String catId) {
    if (catId == 'all') return _foods.length;
    return _foods.where((f) => f['category_id'].toString() == catId).length;
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.softBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Text(
                  '${_foods.length} items',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Manual Cloud Sync Button
          ManualSyncButton(
            isCompact: false,
            onSyncCompleted: () => _loadData(),
          ),
          const SizedBox(width: 12),
          // Search Product Pill
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search product here...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 15, color: Color(0xFF64748B)),
                          onPressed: () => setState(() => _searchQuery = ''),
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.darkCharcoal),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catId = cat['id'].toString();
          final isSelected = catId == _selectedCategoryId;
          final catName = cat['name'].toString().replaceAll(' Foods', '');
          final itemCount = _getCategoryItemCount(catId);
          final iconData = _getCategoryIcon(catName);

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedCategoryId = catId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.goldenYellow
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.goldenYellow : AppColors.softBorder,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.darkCharcoal
                            : AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconData,
                        size: 17,
                        color: isSelected
                            ? AppColors.goldenYellow
                            : AppColors.mutedBrown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$itemCount items',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.darkCharcoal
                                : AppColors.mutedBrown,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      return matchesCat && matchesSearch;
    }).toList();

    if (displayedFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.utensils, size: 40, color: AppColors.mutedBrown),
            const SizedBox(height: 12),
            Text(
              'No food items found.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;

        if (isMobile || availableWidth < 500) {
          crossAxisCount = 2;
          childAspectRatio = 0.82;
        } else if (availableWidth < 700) {
          crossAxisCount = 3;
          childAspectRatio = 0.82;
        } else if (availableWidth < 880) {
          crossAxisCount = 4;
          childAspectRatio = 0.80;
        } else {
          // Desktop POS layout: 5 items per row for compact, proportional food cards
          crossAxisCount = 5;
          childAspectRatio = 0.80;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: GridView.builder(
            key: ValueKey('grid_${_selectedCategoryId}_${_searchQuery.isEmpty ? 'all' : _searchQuery}_$crossAxisCount'),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayedFoods.length,
            itemBuilder: (context, index) {
              final food = displayedFoods[index];
              final cartItem = _orderItems.firstWhere(
                (item) => item['food']['id'].toString() == food['id'].toString(),
                orElse: () => {},
              );
              final inCart = cartItem.isNotEmpty;
              final quantity = inCart ? (cartItem['quantity'] as int? ?? 1) : 0;
              final cartIndex = inCart ? _orderItems.indexOf(cartItem) : -1;

              return FoodCard(
                food: food,
                isInCart: inCart,
                quantity: quantity,
                onAdd: () => _addToOrder(food),
                onRemove: () => _removeFoodFromCart(food['id'].toString()),
                onIncrease: cartIndex >= 0 ? () => _increaseQuantity(cartIndex) : null,
                onDecrease: cartIndex >= 0 ? () => _decreaseQuantity(cartIndex) : null,
              );
            },
          ),
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
  final _orderNumberController = TextEditingController();
  String? _cashError;

  double? get _cashReceived => double.tryParse(_cashController.text.trim());

  @override
  void dispose() {
    _cashController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  void _completeCheckout() {
    if (_cashReceived == null || _cashReceived! < widget.total) {
      setState(() => _cashError = 'Enter an amount that covers the total');
      return;
    }
    if (_cashReceived! > 100000000) {
      setState(() => _cashError = 'Amount exceeds maximum limit (100,000,000)');
      return;
    }
    int? customOrder;
    if (_orderNumberController.text.trim().isNotEmpty) {
      customOrder = int.tryParse(_orderNumberController.text.trim());
    }

    Navigator.pop(context, {
      'amountReceived': _cashReceived!,
      'change': _cashReceived! - widget.total,
      'customOrderNumber': customOrder,
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
                            'Order Number & Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _orderNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Custom Order Number (Optional)',
                          hintText: 'Leave empty to auto-generate',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _cashController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
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
