import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onAdd;

  const FoodCard({super.key, required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAvailable = food['isAvailable'] as bool;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: isAvailable ? onAdd : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(food['image'], fit: BoxFit.cover),
                  if (!isAvailable)
                    Container(
                      color: cs.surface.withValues(alpha: 0.7),
                      child: Center(
                        child: Text(
                          'Unavailable',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food['category'],
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${food['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          fontSize: 16,
                        ),
                      ),
                      if (isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 24, color: Colors.white),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
