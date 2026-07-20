import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/sync_service.dart';

class FoodImage extends StatefulWidget {
  final Map<String, dynamic> food;
  final double height;

  const FoodImage({super.key, required this.food, this.height = 140});

  @override
  State<FoodImage> createState() => _FoodImageState();
}

class _FoodImageState extends State<FoodImage> {
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  @override
  void didUpdateWidget(covariant FoodImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food['image_path'] != widget.food['image_path']) {
      _checkCache();
    }
  }

  Future<void> _checkCache() async {
    final pathStr = widget.food['image_path'] as String?;
    if (pathStr == null || pathStr.isEmpty) return;
    final file = await SyncService.getCachedImageFile(pathStr);
    if (file != null && mounted) {
      setState(() {
        _cachedFile = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.food['name'] as String;
    final isAvailable = widget.food['availability'] == 'available' || widget.food['isAvailable'] == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(widget.food['image_path'] ?? '', name),
        if (!isAvailable)
          Container(
            color: Colors.white.withValues(alpha: 0.6),
            child: Center(
              child: Text(
                'Unavailable',
                style: TextStyle(
                  color: AppColors.brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String path, String name) {
    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(name),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(name);
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(name),
      );
    } else if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(name),
        );
      }
    }

    return _buildPlaceholder(name);
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: AppColors.goldenYellow.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.darkCharcoal,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
