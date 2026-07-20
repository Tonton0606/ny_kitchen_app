import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../core/database/repositories/food_repository.dart';

class FoodManagementPage extends StatefulWidget {
  const FoodManagementPage({super.key});

  @override
  State<FoodManagementPage> createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> {
  String _searchQuery = '';
  bool _showAddFood = false;

  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  final _addNameController = TextEditingController();
  final _addPriceController = TextEditingController();
  int? _addCategoryId;
  bool _addIsAvailable = true;
  String? _addImageUrl;

  @override
  void dispose() {
    _addNameController.dispose();
    _addPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final repo = FoodRepository();
    final foods = await repo.getAllFoodItems();
    final categories = await repo.getCategories();
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _categories = categories;
      _isLoading = false;
    });
  }

  void _openAddFood() {
    _addNameController.clear();
    _addPriceController.clear();
    _addCategoryId = _categories.isNotEmpty
        ? _categories.first['id'] as int
        : null;
    _addIsAvailable = true;
    _addImageUrl = null;
    setState(() => _showAddFood = true);
  }

  void _closeAddFood() => setState(() => _showAddFood = false);

  Future<void> _saveNewFood() async {
    if (_addNameController.text.isEmpty ||
        _addPriceController.text.isEmpty ||
        _addCategoryId == null) {
      return;
    }
    final price = double.tryParse(_addPriceController.text) ?? 0.0;

    final repo = FoodRepository();
    await repo.insertFoodItem({
      'name': _addNameController.text,
      'price': price,
      'category_id': _addCategoryId,
      'availability': _addIsAvailable ? 'available' : 'unavailable',
      'status': 'active',
      'image_path':
          _addImageUrl ??
          'https://placehold.co/300x200/FFCA05/2B241A?text=New+Food&font=raleway',
    });
    if (!mounted) return;
    _closeAddFood();
    await _loadData();
  }

  void _showEditFoodDialog(BuildContext context, Map<String, dynamic> food) {
    bool isAvailable = food['availability'] == 'available';
    int? categoryId = food['category_id'] as int?;
    String? imageUrl = food['image_path'] as String?;
    final nameController = TextEditingController(text: food['name']);
    final priceController = TextEditingController(
      text: food['price'].toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldenYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.goldenYellow,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Edit ${food['name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setDialogState(() => imageUrl = image.path);
                        }
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImagePreview(imageUrl),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: nameController,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      initialValue: categoryId,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => categoryId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\u20b1 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Show this item on the menu'),
                      value: isAvailable,
                      onChanged: (val) {
                        setDialogState(() => isAvailable = val);
                      },
                      activeTrackColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ),
          ),
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
              await repo.updateFoodItem(food['id'] as int, {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'category_id': categoryId,
                'availability': isAvailable ? 'available' : 'unavailable',
                'image_path': imageUrl,
              });
              if (!context.mounted) return;
              Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Update Item',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.brandRed,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Delete Food Item',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete "${food['name']}"?',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.brandRed,
                fontWeight: FontWeight.w500,
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
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static const _chipColors = [
    Color(0xFFFF8C42),
    Color(0xFF9B5DE5),
    Color(0xFF00B4D8),
    Color(0xFFFF6B6B),
    Color(0xFF2EC4B6),
    Color(0xFFFFBE0B),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final filteredFoods = _foods.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return ((f['name'] as String?) ?? '').toLowerCase().contains(q) ||
          ((f['category_name'] as String?) ?? '').toLowerCase().contains(q);
    }).toList();
    final Map<String, String> catIcons = {
      for (final c in _categories)
        c['name'] as String: (c['icon_url'] as String?) ?? '🍽️'
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Food Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal)),
                SizedBox(height: 4),
                Text('Add, edit, and manage menu items', style: TextStyle(color: AppColors.mutedText, fontSize: 14)),
              ]),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showManageCategoriesDialog,
                icon: const Icon(Icons.category_outlined, size: 17),
                label: const Text('Categories'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkCharcoal,
                  side: const BorderSide(color: AppColors.softBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openAddFood,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Food', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldenYellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: 340,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mutedText),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true, fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.softBorder)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
                      ),
                      child: const Row(children: [
                        SizedBox(width: 56, child: Text('Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                        SizedBox(width: 16),
                        Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                        SizedBox(width: 90, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                        SizedBox(width: 110, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                        SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                      ]),
                    ),
                    Expanded(
                      child: filteredFoods.isEmpty
                          ? const Center(child: Text('No food items found.', style: TextStyle(color: AppColors.mutedText)))
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filteredFoods.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.softBorder),
                              itemBuilder: (context, index) {
                                final food = filteredFoods[index];
                                final isAvailable = food['availability'] == 'available';
                                final catName = (food['category_name'] as String?) ?? 'Uncategorized';
                                final catIcon = catIcons[catName] ?? '🍽️';
                                final catIdx = _categories.indexWhere((c) => c['name'] == catName);
                                final chipColor = _chipColors[(catIdx < 0 ? 0 : catIdx) % _chipColors.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Row(children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(width: 56, height: 48, child: _buildImagePreview(food['image_path'], isThumbnail: true))),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 3, child: Text(food['name'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal))),
                                    Expanded(flex: 2, child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: chipColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Text(catIcon, style: const TextStyle(fontSize: 13)),
                                        const SizedBox(width: 5),
                                        Flexible(child: Text(catName, style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                      ]),
                                    )),
                                    SizedBox(width: 90, child: Text('₱${(food["price"] as num).toDouble().toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                    SizedBox(width: 110, child: Row(children: [
                                      Container(width: 7, height: 7, decoration: BoxDecoration(color: isAvailable ? AppColors.success : AppColors.brandRed, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(isAvailable ? 'Available' : 'Unavailable',
                                          style: TextStyle(color: isAvailable ? AppColors.success : AppColors.brandRed, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ])),
                                    SizedBox(width: 80, child: Row(children: [
                                      _buildActionButton(icon: Icons.edit_outlined, color: AppColors.goldenYellow, tooltip: 'Edit', onPressed: () => _showEditFoodDialog(context, food)),
                                      const SizedBox(width: 6),
                                      _buildActionButton(icon: Icons.delete_outline, color: AppColors.brandRed, tooltip: 'Delete', onPressed: () => _showDeleteDialog(context, food)),
                                    ])),
                                  ]),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.softBorder))),
                      child: Text('Showing \ of \ items',
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(width: 190, child: Container(
                decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFE8A3))),
                padding: const EdgeInsets.all(20),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('👨‍🍳', style: TextStyle(fontSize: 52)),
                  SizedBox(height: 16),
                  Text('Delicious Food,', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                  Text('Happy Customers!', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.goldenYellow, fontStyle: FontStyle.italic)),
                  SizedBox(height: 10),
                  Text('Keep your menu updated to serve the best every day.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.5)),
                ]),
              )),
            ])),
          ]),
        ),
        if (_showAddFood) _buildAddFoodPanel(),
      ]),
    );
  }

  Widget _buildAddFoodPanel() {
    return Positioned.fill(
      child: Row(
        children: [
          Container(
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.softBorder)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
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
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.softBorder.withValues(alpha: 0.5),
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
                                        Icons.image_outlined,
                                        size: 36,
                                        color: AppColors.mutedText,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to add image URL',
                                        style: TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 13,
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
                        decoration: const InputDecoration(
                          labelText: 'Food Name',
                          hintText: 'Enter food name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _addCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['name'] as String),
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
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                          prefixText: '\u20b1 ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text(
                          'Available',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        subtitle: const Text(
                          'Show this item on the menu',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                        value: _addIsAvailable,
                        onChanged: (val) {
                          setState(() => _addIsAvailable = val);
                        },
                        activeTrackColor: AppColors.goldenYellow.withValues(
                          alpha: 0.5,
                        ),
                        activeThumbColor: AppColors.goldenYellow,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
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
                            'Save Item',
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
          ),
          Expanded(
            child: GestureDetector(
              onTap: _closeAddFood,
              child: Container(color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.goldenYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: AppColors.goldenYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Add Food Item',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.darkCharcoal,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.darkCharcoal,
            onPressed: _closeAddFood,
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
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImagePreview(String? path, {bool isThumbnail = false}) {
    final height = isThumbnail ? 48.0 : 120.0;
    final double width = isThumbnail ? 48 : double.infinity;

    if (path == null || path.isEmpty) {
      if (isThumbnail) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Icon(Icons.image, color: Colors.grey),
        );
      }
      return const Icon(Icons.image, size: 48);
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => isThumbnail
            ? const Icon(Icons.image)
            : const Icon(Icons.image, size: 48),
      );
    } else {
      return Image.file(
        File(path),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => isThumbnail
            ? const Icon(Icons.image)
            : const Icon(Icons.image, size: 48),
      );
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    final repo = FoodRepository();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final TextEditingController categoryController =
                TextEditingController();
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Manage Categories'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              hintText: 'New Category Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: () async {
                            if (categoryController.text.isNotEmpty) {
                              await repo.insertCategory(
                                categoryController.text,
                              );
                              if (!mounted) return;
                              categoryController.clear();
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
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    cat['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
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
                                          await showDialog(
                                            context: context,
                                            builder: (editCtx) => AlertDialog(
                                              title: const Text(
                                                'Edit Category',
                                              ),
                                              content: TextField(
                                                controller: editController,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Category Name',
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(editCtx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (editController
                                                        .text
                                                        .isNotEmpty) {
                                                      await repo.updateCategory(
                                                        cat['id'],
                                                        editController.text,
                                                      );
                                                      if (!editCtx.mounted) {
                                                        return;
                                                      }
                                                      _loadData();
                                                      Navigator.pop(editCtx);
                                                    }
                                                  },
                                                  child: const Text('Save'),
                                                ),
                                              ],
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
                                          await repo.archiveCategory(cat['id']);
                                          _loadData();
                                          setDialogState(() {});
                                        },
                                      ),
                                    ],
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
