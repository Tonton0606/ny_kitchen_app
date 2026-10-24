import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/food_repository.dart';
import '../widgets/food_icon_picker_dialog.dart';

class FoodManagementPage extends StatefulWidget {
  final bool enableAutoRefresh;
  final List<Map<String, dynamic>>? initialFoods;
  final List<Map<String, dynamic>>? initialCategories;

  const FoodManagementPage({
    super.key,
    this.enableAutoRefresh = true,
    this.initialFoods,
    this.initialCategories,
  });

  @override
  State<FoodManagementPage> createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'none';
  bool _showAddFood = false;
  Map<String, dynamic>? _selectedFood;
  bool _isEditingSelected = false;

  int _currentPage = 1;
  static const int _pageSize = 10;

  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  final _addNameController = TextEditingController();
  final _addPriceController = TextEditingController();
  int? _addCategoryId;
  bool _addIsAvailable = true;
  String? _addImageUrl;

  final _editNameController = TextEditingController();
  final _editPriceController = TextEditingController();
  int? _editCategoryId;
  bool _editIsAvailable = true;
  String? _editImageUrl;

  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _addNameController.dispose();
    _addPriceController.dispose();
    _editNameController.dispose();
    _editPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFoods != null) {
      _foods = List.from(widget.initialFoods!);
      _categories = List.from(widget.initialCategories ?? []);
      _isLoading = false;
    } else {
      _loadData();
    }
    if (widget.enableAutoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _loadDataSilent();
      });
    }
  }

  Future<void> _loadDataSilent() async {
    if (!mounted || _isEditingSelected || _showAddFood) return;
    final repo = FoodRepository();
    final foods = await repo.getAllFoodItems(includeArchived: true);
    final categories = await repo.getCategories();
    if (!mounted || _isEditingSelected || _showAddFood) return;
    setState(() {
      _foods = foods;
      _categories = categories;
      final maxPages = (foods.length + _pageSize - 1) ~/ _pageSize;
      if (_currentPage > maxPages && maxPages > 0) {
        _currentPage = maxPages;
      }
      if (_selectedFood != null) {
        final match = foods.where((f) => f['id'] == _selectedFood!['id']);
        if (match.isNotEmpty) {
          _selectedFood = match.first;
        }
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final repo = FoodRepository();
    final foods = await repo.getAllFoodItems(includeArchived: true);
    final categories = await repo.getCategories();
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _categories = categories;
      final maxPages = (foods.length + _pageSize - 1) ~/ _pageSize;
      if (_currentPage > maxPages && maxPages > 0) {
        _currentPage = maxPages;
      }
      if (_selectedFood != null) {
        final match = foods.where((f) => f['id'] == _selectedFood!['id']);
        if (match.isNotEmpty) {
          _selectedFood = match.first;
        }
      }
      _isLoading = false;
    });
  }

  void _openAddFood() {
    _addNameController.clear();
    _addPriceController.clear();
    final matchingCat = _categories.where((c) => c['name'] == _selectedCategory);
    _addCategoryId = matchingCat.isNotEmpty
        ? matchingCat.first['id'] as int
        : (_categories.isNotEmpty ? _categories.first['id'] as int : null);
    _addIsAvailable = true;
    _addImageUrl = null;
    setState(() {
      _showAddFood = true;
      _selectedFood = null;
      _isEditingSelected = false;
    });
  }

  void _closeAddFood() => setState(() => _showAddFood = false);

  void _selectFood(Map<String, dynamic> food) {
    setState(() {
      _selectedFood = food;
      _showAddFood = false;
      _isEditingSelected = false;
    });
  }

  void _startEditingSelectedFood() {
    if (_selectedFood == null) return;
    _editNameController.text = _selectedFood!['name'] ?? '';
    _editPriceController.text = (_selectedFood!['price'] as num?)?.toString() ?? '0';
    _editCategoryId = _selectedFood!['category_id'] as int?;
    _editIsAvailable = _selectedFood!['availability'] == 'available';
    _editImageUrl = _selectedFood!['image_path'] as String?;
    setState(() {
      _isEditingSelected = true;
      _showAddFood = false;
    });
  }

  Future<void> _saveEditedFood() async {
    if (_selectedFood == null) return;
    final name = _editNameController.text.trim();
    final price = double.tryParse(_editPriceController.text.trim()) ?? 0.0;
    if (name.isEmpty ||
        name.length > 50 ||
        price <= 0 ||
        price > 99999.99 ||
        _editCategoryId == null) {
      return;
    }
    final foodId = _selectedFood!['id'] as int;

    try {
      final repo = FoodRepository();
      await repo.updateFoodItem(foodId, {
        'name': _editNameController.text.trim(),
        'price': price,
        'category_id': _editCategoryId,
        'availability': _editIsAvailable ? 'available' : 'unavailable',
        'image_path': _editImageUrl,
      });
      if (!mounted) return;
      final updatedFoods = await repo.getAllFoodItems(includeArchived: true);
      final updatedItem = updatedFoods.firstWhere(
        (f) => f['id'] == foodId,
        orElse: () => {
          ..._selectedFood!,
          'name': _editNameController.text.trim(),
          'price': price,
          'category_id': _editCategoryId,
          'availability': _editIsAvailable ? 'available' : 'unavailable',
          'image_path': _editImageUrl,
        },
      );
      if (!mounted) return;
      setState(() {
        _foods = updatedFoods;
        _selectedFood = updatedItem;
        _isEditingSelected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e
          .toString()
          .replaceFirst('SecurityException: ', '')
          .replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.brandRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleSelectedFoodAvailability(bool val) async {
    if (_selectedFood == null) return;
    final foodId = _selectedFood!['id'] as int;
    final repo = FoodRepository();
    await repo.updateFoodItem(foodId, {
      'availability': val ? 'available' : 'unavailable',
    });
    if (!mounted) return;
    final updatedFoods = await repo.getAllFoodItems(includeArchived: true);
    final updatedItem = updatedFoods.firstWhere(
      (f) => f['id'] == foodId,
      orElse: () => {
        ..._selectedFood!,
        'availability': val ? 'available' : 'unavailable',
      },
    );
    setState(() {
      _foods = updatedFoods;
      _selectedFood = updatedItem;
    });
  }

  Future<void> _saveNewFood() async {
    final name = _addNameController.text.trim();
    final price = double.tryParse(_addPriceController.text.trim()) ?? 0.0;
    if (name.isEmpty ||
        name.length > 50 ||
        price <= 0 ||
        price > 99999.99 ||
        _addCategoryId == null) {
      return;
    }

    try {
      final repo = FoodRepository();
      await repo.insertFoodItem({
        'name': name,
        'price': price,
        'category_id': _addCategoryId,
        'availability': _addIsAvailable ? 'available' : 'unavailable',
        'status': 'active',
        'image_path': _addImageUrl ?? '',
      });
      if (!mounted) return;
      _closeAddFood();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dish "$name" added successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e
          .toString()
          .replaceFirst('SecurityException: ', '')
          .replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.brandRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showArchiveDialog(BuildContext context, Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.archive_outlined,
                color: Color(0xFFD97706),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Archive Food Item',
                style: AppTypography.dialogTitle,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive "${food['name']}"?',
              style: const TextStyle(fontSize: 15, color: AppColors.mutedText),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'This dish will be removed from the active cashier menu. Past sales and receipts will remain intact. You can restore it anytime from the Archived filter.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = FoodRepository();
              await repo.archiveFoodItem(food['id'] as int);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (_selectedFood != null && _selectedFood!['id'] == food['id']) {
                setState(() {
                  _selectedFood = null;
                  _isEditingSelected = false;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${food['name']}" archived successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Archive Dish',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveDialog(BuildContext context, Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.unarchive_outlined,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Restore Food Item',
                style: AppTypography.dialogTitle,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore "${food['name']}" to the active menu?',
              style: const TextStyle(fontSize: 15, color: AppColors.mutedText),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'This dish will become active again and available for cashiers to order.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = FoodRepository();
              await repo.unarchiveFoodItem(food['id'] as int);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (_selectedFood != null && _selectedFood!['id'] == food['id']) {
                setState(() {
                  _selectedFood = null;
                  _isEditingSelected = false;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${food['name']}" restored to active menu.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Restore Dish',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    var filteredFoods = _foods.where((f) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = ((f['name'] as String?) ?? '').toLowerCase().contains(q) ||
            ((f['category_name'] as String?) ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_selectedCategory != 'All') {
        if ((f['category_name'] as String?) != _selectedCategory) {
          return false;
        }
      }
      final status = (f['status'] as String? ?? 'active').toLowerCase();
      if (_selectedStatus == 'All') {
        if (status == 'archived') return false;
      } else if (_selectedStatus == 'archived') {
        if (status != 'archived') return false;
      } else {
        if (status == 'archived') return false;
        if ((f['availability'] as String?) != _selectedStatus) {
          return false;
        }
      }
      return true;
    }).toList();

    if (_sortBy == 'name_asc') {
      filteredFoods.sort((a, b) => ((a['name'] as String?) ?? '').toLowerCase().compareTo(((b['name'] as String?) ?? '').toLowerCase()));
    } else if (_sortBy == 'name_desc') {
      filteredFoods.sort((a, b) => ((b['name'] as String?) ?? '').toLowerCase().compareTo(((a['name'] as String?) ?? '').toLowerCase()));
    } else if (_sortBy == 'price_asc') {
      filteredFoods.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
    } else if (_sortBy == 'price_desc') {
      filteredFoods.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
    }
    final Map<String, String> catIcons = {
      for (final c in _categories)
        c['name'] as String: (c['icon_url'] as String?) ?? 'utensils',
    };
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, topConstraints) {
                    final isCompact = topConstraints.maxWidth < 900;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Search Field
                            SizedBox(
                              width: isCompact ? 220 : 280,
                              height: 44,
                              child: TextField(
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(100),
                                ],
                                onChanged: (val) => setState(() {
                                  _searchQuery = val;
                                  _currentPage = 1;
                                }),
                                decoration: InputDecoration(
                                  hintText: 'Search foods...',
                                  hintStyle: AppTypography.bodyMuted.copyWith(fontSize: 13),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: AppColors.mutedSlate,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                    borderSide: const BorderSide(color: AppColors.softBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                    borderSide: const BorderSide(color: AppColors.softBorder),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                  filled: true,
                                  fillColor: AppColors.surfaceWhite,
                                ),
                              ),
                            ),
                            // Category Filter Dropdown
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                border: Border.all(
                                  color: _selectedCategory != 'All'
                                      ? AppColors.goldenYellow
                                      : AppColors.softBorder,
                                  width: _selectedCategory != 'All' ? 1.5 : 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _categories.any((c) => c['name'] == _selectedCategory) || _selectedCategory == 'All'
                                      ? _selectedCategory
                                      : 'All',
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedSlate),
                                  style: AppTypography.body.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (val) => setState(() {
                                    _selectedCategory = val ?? 'All';
                                    _currentPage = 1;
                                  }),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'All',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.category_outlined, size: 16, color: AppColors.mutedSlate),
                                          SizedBox(width: 8),
                                          Text('All Categories'),
                                        ],
                                      ),
                                    ),
                                    ..._categories.map((c) {
                                      final name = c['name'] as String;
                                      final icon = (c['icon_url'] as String?) ?? 'utensils';
                                      return DropdownMenuItem(
                                        value: name,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            buildCategoryIconWidget(icon, size: 14),
                                            const SizedBox(width: 8),
                                            Text(name),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            // Status Filter Dropdown
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                border: Border.all(
                                  color: _selectedStatus != 'All'
                                      ? AppColors.goldenYellow
                                      : AppColors.softBorder,
                                  width: _selectedStatus != 'All' ? 1.5 : 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedSlate),
                                  style: AppTypography.body.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (val) => setState(() {
                                    _selectedStatus = val ?? 'All';
                                    _currentPage = 1;
                                  }),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All Active'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'available',
                                      child: Text('Available'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'unavailable',
                                      child: Text('Unavailable'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'archived',
                                      child: Text('Archived'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Clear Filters Button
                            if (_selectedCategory != 'All' || _selectedStatus != 'All' || _searchQuery.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => setState(() {
                                  _selectedCategory = 'All';
                                  _selectedStatus = 'All';
                                  _searchQuery = '';
                                  _sortBy = 'none';
                                  _currentPage = 1;
                                }),
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const Text('Clear Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandRed,
                                  side: BorderSide(color: AppColors.brandRed.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radius12)),
                                ),
                              ),
                          ],
                        ),
                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showManageCategoriesDialog,
                              icon: const Icon(
                                Icons.category_outlined,
                                size: 17,
                              ),
                              label: const Text('Categories'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.darkCharcoal,
                                side: const BorderSide(
                                  color: AppColors.softBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                ),
                                backgroundColor: AppColors.surfaceWhite,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _openAddFood,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Add Food',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldenYellow,
                                foregroundColor: AppColors.darkCharcoal,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      final bool isPanelOpen = _selectedFood != null || _showAddFood;
                      final bool showSideBySide = bodyConstraints.maxWidth >= 900;

                      return Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFoodTableContainer(
                                  filteredFoods,
                                  catIcons,
                                  bodyConstraints,
                                  showSideBySide && isPanelOpen,
                                ),
                              ),
                              if (showSideBySide && isPanelOpen) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 400,
                                  height: bodyConstraints.maxHeight,
                                  child: _buildRightSidePanel(),
                                ),
                              ],
                            ],
                          ),
                          if (!showSideBySide && isPanelOpen)
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFood = null;
                                          _showAddFood = false;
                                          _isEditingSelected = false;
                                        });
                                      },
                                      child: Container(color: Colors.black45),
                                    ),
                                  ),
                                  SizedBox(
                                    width: bodyConstraints.maxWidth > 440
                                        ? 420.0
                                        : bodyConstraints.maxWidth,
                                    height: bodyConstraints.maxHeight,
                                    child: _buildRightSidePanel(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTableContainer(
    List<Map<String, dynamic>> filteredFoods,
    Map<String, String> catIcons,
    BoxConstraints constraints,
    bool isSidePanelVisible,
  ) {
    final double availableWidth = isSidePanelVisible
        ? constraints.maxWidth - 416.0
        : constraints.maxWidth;
    final double minTableWidth = isSidePanelVisible ? 680.0 : 820.0;
    final double tableWidth = availableWidth < minTableWidth ? minTableWidth : availableWidth;

    final totalPages = (filteredFoods.isEmpty)
        ? 1
        : ((filteredFoods.length + _pageSize - 1) ~/ _pageSize);
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize > filteredFoods.length)
        ? filteredFoods.length
        : startIndex + _pageSize;
    final pagedFoods = filteredFoods.isEmpty
        ? <Map<String, dynamic>>[]
        : filteredFoods.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.softBorder),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 56,
                      child: Text(
                        'IMAGE',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () => setState(() {
                            _sortBy = _sortBy == 'name_asc' ? 'name_desc' : 'name_asc';
                          }),
                          child: Row(
                            children: [
                              const Text(
                                'NAME',
                                style: AppTypography.tableHeader,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _sortBy == 'name_asc'
                                    ? Icons.arrow_upward
                                    : (_sortBy == 'name_desc' ? Icons.arrow_downward : Icons.swap_vert),
                                size: 14,
                                color: _sortBy.startsWith('name')
                                    ? AppColors.goldenYellow
                                    : AppColors.mutedText.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          'CATEGORY',
                          style: AppTypography.tableHeader,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () => setState(() {
                            _sortBy = _sortBy == 'price_asc' ? 'price_desc' : 'price_asc';
                          }),
                          child: Row(
                            children: [
                              const Text(
                                'PRICE',
                                style: AppTypography.tableHeader,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _sortBy == 'price_asc'
                                    ? Icons.arrow_upward
                                    : (_sortBy == 'price_desc' ? Icons.arrow_downward : Icons.swap_vert),
                                size: 14,
                                color: _sortBy.startsWith('price')
                                    ? AppColors.goldenYellow
                                    : AppColors.mutedText.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'STATUS',
                          style: AppTypography.tableHeader,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'ACTIONS',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredFoods.isEmpty
                    ? const Center(
                        child: Text(
                          'No food items found.',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: pagedFoods.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.softBorder,
                        ),
                        itemBuilder: (context, index) {
                          final food = pagedFoods[index];
                          final isArchived = (food['status'] as String? ?? '').toLowerCase() == 'archived';
                          final isAvailable = food['availability'] == 'available';
                          final isSelected = _selectedFood != null && _selectedFood!['id'] == food['id'];
                          final catName = (food['category_name'] as String?) ?? 'Uncategorized';
                          final catIcon = catIcons[catName] ?? 'utensils';

                          return InkWell(
                            onTap: () => _selectFood(food),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.goldenYellow.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: isSelected
                                    ? const Border(
                                        left: BorderSide(
                                          color: AppColors.goldenYellow,
                                          width: 4,
                                        ),
                                      )
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Opacity(
                                opacity: isArchived ? 0.65 : (isAvailable ? 1.0 : 0.45),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 56,
                                        height: 48,
                                        child: _buildImagePreview(
                                          food['image_path'],
                                          isThumbnail: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Text(
                                          food['name'] ?? 'Unknown',
                                          style: isSelected
                                              ? AppTypography.tableCellPrimary.copyWith(fontWeight: FontWeight.w800)
                                              : AppTypography.tableCellPrimary,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.pageBackground,
                                              borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                                              border: Border.all(color: AppColors.softBorder),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                buildCategoryIconWidget(catIcon, size: 13, color: AppColors.mutedSlate),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    catName,
                                                    style: AppTypography.caption.copyWith(
                                                      color: AppColors.darkCharcoal,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Text(
                                          '₱${(food["price"] as num).toDouble().toStringAsFixed(2)}',
                                          style: AppTypography.tableCellPrimary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: isArchived
                                                    ? const Color(0xFFD97706)
                                                    : (isAvailable ? AppColors.success : AppColors.brandRed),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                isArchived
                                                    ? 'Archived'
                                                    : (isAvailable ? 'Available' : 'Unavailable'),
                                                style: AppTypography.badgeLabel.copyWith(
                                                  color: isArchived
                                                      ? const Color(0xFFD97706)
                                                      : (isAvailable ? AppColors.success : AppColors.brandRed),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Row(
                                        children: [
                                          if (!isArchived) ...[
                                            _buildActionButton(
                                              icon: Icons.edit_outlined,
                                              color: AppColors.goldenYellow,
                                              tooltip: 'Edit in Panel',
                                              onPressed: () {
                                                _selectFood(food);
                                                _startEditingSelectedFood();
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            _buildActionButton(
                                              icon: Icons.archive_outlined,
                                              color: const Color(0xFFD97706),
                                              tooltip: 'Archive Dish',
                                              onPressed: () => _showArchiveDialog(context, food),
                                            ),
                                          ] else ...[
                                            _buildActionButton(
                                              icon: Icons.unarchive_outlined,
                                              color: AppColors.success,
                                              tooltip: 'Restore Dish',
                                              onPressed: () => _showUnarchiveDialog(context, food),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.softBorder)),
                ),
                child: Row(
                  children: [
                    Text(
                      filteredFoods.isEmpty
                          ? 'Showing 0 items'
                          : 'Showing ${startIndex + 1}–$endIndex of ${filteredFoods.length} items',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedFood != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Selected: ${_selectedFood!['name']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _buildPaginationControls(currentPage, totalPages),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages) {
    final List<int> pages = [];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      if (currentPage <= 4) {
        pages.addAll([1, 2, 3, 4, 5, -1, totalPages]);
      } else if (currentPage >= totalPages - 3) {
        pages.addAll([
          1,
          -1,
          totalPages - 4,
          totalPages - 3,
          totalPages - 2,
          totalPages - 1,
          totalPages,
        ]);
      } else {
        pages.addAll([
          1,
          -1,
          currentPage - 1,
          currentPage,
          currentPage + 1,
          -1,
          totalPages,
        ]);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => setState(() => _currentPage = currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left, size: 20),
          color: AppColors.darkCharcoal,
          disabledColor: AppColors.mutedText.withValues(alpha: 0.35),
          tooltip: 'Previous page',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        ...pages.map((p) {
          if (p == -1) {
            return const SizedBox(
              width: 24,
              height: 32,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          final isSelected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _currentPage = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldenYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.softBorder),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.black : AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentPage = currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right, size: 20),
          color: AppColors.darkCharcoal,
          disabledColor: AppColors.mutedText.withValues(alpha: 0.35),
          tooltip: 'Next page',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildRightSidePanel() {
    Widget content;
    if (_showAddFood) {
      content = _buildAddFoodPanelContent();
    } else if (_selectedFood != null && _isEditingSelected) {
      content = _buildEditFoodPanelContent();
    } else if (_selectedFood != null) {
      content = _buildFoodDetailsPanelContent();
    } else {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: content,
    );
  }

  Widget _buildFoodDetailsPanelContent() {
    final food = _selectedFood!;
    final isArchived = (food['status'] as String? ?? '').toLowerCase() == 'archived';
    final isAvailable = food['availability'] == 'available';
    final catName = (food['category_name'] as String?) ?? 'Uncategorized';
    final catIcon = _categories.firstWhere(
      (c) => c['name'] == catName,
      orElse: () => {'icon_url': 'utensils'},
    )['icon_url'] as String? ?? 'utensils';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.softBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.darkCharcoal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Food Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkCharcoal,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.darkCharcoal,
                  tooltip: 'Close panel',
                  onPressed: () => setState(() => _selectedFood = null),
                ),
              ],
            ),
          ),
          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Food Image Hero
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImagePreview(food['image_path']),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isArchived
                                        ? const Color(0xFFD97706)
                                        : (isAvailable ? AppColors.success : AppColors.brandRed),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isArchived
                                      ? 'Archived'
                                      : (isAvailable ? 'Available' : 'Unavailable'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isArchived
                                        ? const Color(0xFFD97706)
                                        : (isAvailable ? AppColors.success : AppColors.brandRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Food Title & Category
                Text(
                  food['name'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkCharcoal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildCategoryIconWidget(catIcon, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            catName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Price',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                      Text(
                        '₱${(food['price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (isArchived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 20, color: Color(0xFFD97706)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This dish is archived. It is hidden from active orders in the cashier POS.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Availability quick toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Menu Availability',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAvailable ? 'Visible and orderable in POS' : 'Hidden from active orders',
                                style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAvailable,
                          activeTrackColor: AppColors.goldenYellow.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.goldenYellow,
                          onChanged: (val) => _toggleSelectedFoodAvailability(val),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (isArchived) ...[
                  // Restore Dish Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUnarchiveDialog(context, food),
                      icon: const Icon(Icons.unarchive_outlined, size: 18),
                      label: const Text(
                        'Restore Dish to Menu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _startEditingSelectedFood,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Food Item',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldenYellow,
                        foregroundColor: AppColors.darkCharcoal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Archive Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _showArchiveDialog(context, food),
                      icon: const Icon(Icons.archive_outlined, size: 18, color: Color(0xFFD97706)),
                      label: const Text(
                        'Archive Dish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditFoodPanelContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.softBorder),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  color: AppColors.darkCharcoal,
                  tooltip: 'Back to details',
                  onPressed: () => setState(() => _isEditingSelected = false),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Edit Food Item',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.darkCharcoal,
                  tooltip: 'Close panel',
                  onPressed: () => setState(() {
                    _selectedFood = null;
                    _isEditingSelected = false;
                  }),
                ),
              ],
            ),
          ),
          // Scrollable Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Image Picker / Preview
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => _editImageUrl = image.path);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Center(
                      child: _editImageUrl != null && _editImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImagePreview(_editImageUrl),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 34,
                                  color: AppColors.mutedText,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to change photo',
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editNameController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('edit_cat_$_editCategoryId'),
                  initialValue: _categories.any((c) => c['id'] == _editCategoryId) ? _editCategoryId : null,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildCategoryIconWidget(c['icon_url'] as String?, size: 16),
                              const SizedBox(width: 8),
                              Text(c['name'] as String),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _editCategoryId = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editPriceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available on Menu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Show this item on active orders',
                              style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _editIsAvailable,
                        activeTrackColor: AppColors.goldenYellow.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.goldenYellow,
                        onChanged: (val) {
                          setState(() => _editIsAvailable = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditingSelected = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.softBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveEditedFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFoodPanelContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.softBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.darkCharcoal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Add Food Item',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.darkCharcoal,
                  tooltip: 'Close panel',
                  onPressed: _closeAddFood,
                ),
              ],
            ),
          ),
          // Scrollable Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Image selector
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => _addImageUrl = image.path);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Center(
                      child: _addImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImagePreview(_addImageUrl),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 34,
                                  color: AppColors.mutedText,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to upload food image',
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addNameController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    hintText: 'e.g. Pastil Special',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('add_cat_$_addCategoryId'),
                  initialValue: _categories.any((c) => c['id'] == _addCategoryId) ? _addCategoryId : null,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildCategoryIconWidget(c['icon_url'] as String?, size: 16),
                              const SizedBox(width: 8),
                              Text(c['name'] as String),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _addCategoryId = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addPriceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available on Menu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Show this item on active orders',
                              style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _addIsAvailable,
                        activeTrackColor: AppColors.goldenYellow.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.goldenYellow,
                        onChanged: (val) {
                          setState(() => _addIsAvailable = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _saveNewFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldenYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Food Item',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildImagePreview(String? path, {bool isThumbnail = false}) {
    final height = isThumbnail ? 48.0 : 120.0;
    final double width = isThumbnail ? 48 : double.infinity;

    Widget buildPlaceholder() {
      if (isThumbnail) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Icon(Icons.image, color: Colors.grey),
        );
      }
      return Container(
        height: height,
        width: width,
        color: Colors.grey.withValues(alpha: 0.2),
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    if (path == null || path.isEmpty) {
      return buildPlaceholder();
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
      );
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return buildPlaceholder();
      }
      return Image.file(
        file,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
      );
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    final repo = FoodRepository();
    String newCategoryIcon = 'utensils';
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.category, color: AppColors.brandRed),
                  SizedBox(width: 8),
                  Text('Manage Categories'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            final selected = await showDialog<String>(
                              context: context,
                              builder: (_) => FoodIconPickerDialog(
                                currentIcon: newCategoryIcon,
                              ),
                            );
                            if (selected != null) {
                              setDialogState(() => newCategoryIcon = selected);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: buildCategoryIconWidget(newCategoryIcon, size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(30),
                            ],
                            decoration: InputDecoration(
                              hintText: 'New Category Name',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.goldenYellow, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldenYellow,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (categoryController.text.trim().isNotEmpty) {
                              await repo.insertCategory(
                                categoryController.text.trim(),
                                iconUrl: newCategoryIcon,
                              );
                              categoryController.clear();
                              newCategoryIcon = 'utensils';
                              if (!mounted) return;
                              _loadData();
                              setDialogState(() {});
                            }
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: repo.getCategories(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final cats = snapshot.data!;
                          if (cats.isEmpty) {
                            return const Center(
                              child: Text(
                                'No categories available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: cats.length,
                            itemBuilder: (context, index) {
                              final cat = cats[index];
                              final String iconStr = (cat['icon_url'] as String?) ?? 'utensils';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: buildCategoryIconWidget(iconStr, size: 20),
                                  ),
                                  title: Text(
                                    cat['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: AppColors.mutedText,
                                        ),
                                        onPressed: () async {
                                          final editController =
                                              TextEditingController(
                                                text: cat['name'],
                                              );
                                          String editIcon = iconStr;

                                          await showDialog(
                                            context: context,
                                            builder: (editCtx) => StatefulBuilder(
                                              builder: (ctx2, setEditState) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                ),
                                                title: const Text('Edit Category'),
                                                content: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        final picked = await showDialog<String>(
                                                          context: editCtx,
                                                          builder: (_) => FoodIconPickerDialog(
                                                            currentIcon: editIcon,
                                                          ),
                                                        );
                                                        if (picked != null) {
                                                          setEditState(() => editIcon = picked);
                                                        }
                                                      },
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Container(
                                                        width: 48,
                                                        height: 48,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: const Color(0xFFE2E8F0),
                                                          ),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: buildCategoryIconWidget(editIcon, size: 22),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: editController,
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(30),
                                                        ],
                                                        decoration: InputDecoration(
                                                          hintText: 'Category Name',
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            borderSide: const BorderSide(color: AppColors.goldenYellow, width: 1.5),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(editCtx),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.goldenYellow,
                                                      foregroundColor: Colors.black,
                                                      elevation: 0,
                                                    ),
                                                    onPressed: () async {
                                                      if (editController.text.trim().isNotEmpty) {
                                                        await repo.updateCategory(
                                                          cat['id'],
                                                          editController.text.trim(),
                                                          iconUrl: editIcon,
                                                        );
                                                        if (!editCtx.mounted) return;
                                                        _loadData();
                                                        Navigator.pop(editCtx);
                                                      }
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          setDialogState(() {});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (confirmCtx) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              surfaceTintColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                              ),
                                              title: Row(
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, color: AppColors.brandRed),
                                                  const SizedBox(width: 8),
                                                  const Text('Delete Category?'),
                                                ],
                                              ),
                                              content: Text('Are you sure you want to delete "${cat['name']}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(confirmCtx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandRed),
                                                  onPressed: () => Navigator.pop(confirmCtx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            await repo.archiveCategory(cat['id']);
                                            _loadData();
                                            setDialogState(() {});
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
