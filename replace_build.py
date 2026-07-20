import re

path = r'lib\features\admin\presentation\pages\food_management_page.dart'
src = open(path, encoding='utf-8').read()

# Find start of build method
build_start = src.index('  @override\r\n  Widget build(BuildContext context)')

# Find the line after build end - look for "  Widget _buildAddFoodPanel"
panel_start = src.index('  Widget _buildAddFoodPanel()')

new_build = r"""  static const _chipColors = [
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
        c['name'] as String: (c['icon_url'] as String?) ?? '\u{1F37D}\u{FE0F}'
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food Management',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal)),
                        SizedBox(height: 4),
                        Text('Add, edit, and manage menu items',
                            style: TextStyle(color: AppColors.mutedText, fontSize: 14)),
                      ],
                    ),
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
                  ],
                ),
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.softBorder),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAF8F5),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  border: Border(bottom: BorderSide(color: AppColors.softBorder)),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 56, child: Text('Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                    SizedBox(width: 16),
                                    Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                    Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                    SizedBox(width: 90, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                    SizedBox(width: 110, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                    SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                  ],
                                ),
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
                                          final catIcon = catIcons[catName] ?? '\u{1F37D}\u{FE0F}';
                                          final catIdx = _categories.indexWhere((c) => c['name'] == catName);
                                          final chipColor = _chipColors[(catIdx < 0 ? 0 : catIdx) % _chipColors.length];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: SizedBox(width: 56, height: 48, child: _buildImagePreview(food['image_path'], isThumbnail: true)),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(food['name'] ?? 'Unknown',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal)),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(color: chipColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(catIcon, style: const TextStyle(fontSize: 13)),
                                                        const SizedBox(width: 5),
                                                        Flexible(child: Text(catName, style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 90,
                                                  child: Text('\u20b1${(food['price'] as num).toDouble().toStringAsFixed(2)}',
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                ),
                                                SizedBox(
                                                  width: 110,
                                                  child: Row(
                                                    children: [
                                                      Container(width: 7, height: 7, decoration: BoxDecoration(color: isAvailable ? AppColors.success : AppColors.brandRed, shape: BoxShape.circle)),
                                                      const SizedBox(width: 6),
                                                      Text(isAvailable ? 'Available' : 'Unavailable',
                                                          style: TextStyle(color: isAvailable ? AppColors.success : AppColors.brandRed, fontWeight: FontWeight.w600, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 80,
                                                  child: Row(
                                                    children: [
                                                      _buildActionButton(icon: Icons.edit_outlined, color: AppColors.goldenYellow, tooltip: 'Edit', onPressed: () => _showEditFoodDialog(context, food)),
                                                      const SizedBox(width: 6),
                                                      _buildActionButton(icon: Icons.delete_outline, color: AppColors.brandRed, tooltip: 'Delete', onPressed: () => _showDeleteDialog(context, food)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.softBorder))),
                                child: Text('Showing ${filteredFoods.length} of ${_foods.length} items',
                                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 190,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFE8A3)),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('\U0001F468\u200D\U0001F373', style: TextStyle(fontSize: 52)),
                              SizedBox(height: 16),
                              Text('Delicious Food,', textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                              Text('Happy Customers!', textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.goldenYellow, fontStyle: FontStyle.italic)),
                              SizedBox(height: 10),
                              Text('Keep your menu updated to serve the best every day.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showAddFood) _buildAddFoodPanel(),
        ],
      ),
    );
  }

"""

new_content = src[:build_start] + new_build + src[panel_start:]
open(path, 'w', encoding='utf-8').write(new_content)
lines = new_content.count('\n')
print(f'Done! New line count: {lines}')
