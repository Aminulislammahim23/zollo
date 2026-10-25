import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _categoryItem(context, Icons.checkroom_outlined, 'Fashion'),
          _categoryItem(context, Icons.phone_android_outlined, 'Electronics'),
          _categoryItem(context, Icons.shopping_basket_outlined, 'Groceries'),
          _categoryItem(context, Icons.face_outlined, 'Beauty'),
          _categoryItem(context, Icons.home_outlined, 'Home'),
        ],
      ),
    );
  }

  Widget _categoryItem(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => context.go('/categories'),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: const Color(0xFF006B54), size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
