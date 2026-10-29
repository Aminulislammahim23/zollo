import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String? imageUrl;

  const Category({required this.id, required this.name, this.imageUrl});

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Category.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'] as String?;
    return Category(
      id: json['id'].toString(),
      name: (json['name'] ?? 'Category').toString(),
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }

  /// Outlined Material icon that best matches the category name.
  IconData get icon {
    final n = name.toLowerCase();
    if (n.contains('electronic') || n.contains('gadget')) return Icons.devices_outlined;
    if (n.contains('phone') || n.contains('mobile')) return Icons.smartphone_outlined;
    if (n.contains('computer') || n.contains('laptop')) return Icons.laptop_outlined;
    if (n.contains('fashion') || n.contains('cloth') || n.contains('apparel')) {
      return Icons.checkroom_outlined;
    }
    if (n.contains('shoe') || n.contains('footwear')) return Icons.ice_skating_outlined;
    if (n.contains('beauty') || n.contains('cosmetic') || n.contains('health')) {
      return Icons.spa_outlined;
    }
    if (n.contains('home') || n.contains('living') || n.contains('furniture')) {
      return Icons.chair_outlined;
    }
    if (n.contains('kitchen')) return Icons.kitchen_outlined;
    if (n.contains('grocer') || n.contains('food')) return Icons.local_grocery_store_outlined;
    if (n.contains('sport') || n.contains('fitness')) return Icons.sports_soccer_outlined;
    if (n.contains('book') || n.contains('station')) return Icons.menu_book_outlined;
    if (n.contains('toy') || n.contains('kid') || n.contains('baby')) return Icons.toys_outlined;
    if (n.contains('watch') || n.contains('jewel') || n.contains('accessor')) {
      return Icons.watch_outlined;
    }
    if (n.contains('car') || n.contains('motor') || n.contains('auto')) {
      return Icons.directions_car_outlined;
    }
    if (n.contains('pet')) return Icons.pets_outlined;
    return Icons.category_outlined;
  }
}
