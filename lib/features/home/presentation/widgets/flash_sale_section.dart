import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/products/presentation/widgets/product_card.dart';

class FlashSaleSection extends StatelessWidget {
  final List<Product> products;

  const FlashSaleSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Flash Sale',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _timeBox('02'),
                  const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                  _timeBox('14'),
                  const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                  _timeBox('36'),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/categories'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF006B54),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.take(5).length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(product: product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
