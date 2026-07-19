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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredFoods = _foods.where((f) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (f['name'] as String?)?.toLowerCase() ?? '';
      final category = (f['category_name'] as String?)?.toLowerCase() ?? '';
      return name.contains(query) || category.contains(query);
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Food Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add, edit, and manage menu items',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _showManageCategoriesDialog,
                          icon: const Icon(Icons.category_outlined, size: 18),
                          label: const Text('Categories'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkCharcoal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _openAddFood,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Food'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldenYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: SizedBox(
                  width: 360,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 60,
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Image',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      rows: filteredFoods.map((food) {
                        final isAvailable = food['availability'] == 'available';
                        return DataRow(
                          cells: [
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImagePreview(
                                    food['image_path'],
                                    isThumbnail: true,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                food['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  food['category_name'] ?? 'Uncategorized',
                                  style: TextStyle(
                                    color: AppColors.goldenYellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\u20b1${(food['price'] as num).toDouble().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.error
                                            .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAvailable ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color: isAvailable
                                        ? AppColors.success
                                        : AppColors.brandRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: AppColors.goldenYellow,
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _showEditFoodDialog(context, food),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    color: AppColors.brandRed,
                                    tooltip: 'Delete',
                                    onPressed: () =>
                                        _showDeleteDialog(context, food),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showAddFood) _buildAddFoodPanel(),
        ],
      ),
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
