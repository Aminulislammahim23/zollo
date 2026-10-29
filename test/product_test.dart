import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/products/domain/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('parses legacy product JSON format correctly', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Headphones',
        'description': 'Wireless headphones',
        'price': 2499,
        'image': 'https://example.com/headphones.jpg',
        'category': 'Electronics',
        'rating': {'rate': 4.5},
        'stock': 10,
      });

      expect(product.id, '1');
      expect(product.title, 'Headphones');
      expect(product.price, 2499.0);
      expect(product.imageUrl, 'https://example.com/headphones.jpg');
      expect(product.category, 'Electronics');
      expect(product.rating, 4.5);
      expect(product.stock, 10);
    });

    test('parses Supabase products table row format correctly', () {
      final product = Product.fromJson({
        'id': 'p-100',
        'name': 'Wireless Bluetooth Earbuds',
        'description': 'High quality sound earbuds',
        'price': 1850.0,
        'image_url': 'https://images.unsplash.com/photo-earbuds.jpg',
        'stock_quantity': 25,
        'rating': 4.8,
        'categories': {'name': 'Audio & Headphones'},
      });

      expect(product.id, 'p-100');
      expect(product.title, 'Wireless Bluetooth Earbuds');
      expect(product.price, 1850.0);
      expect(product.imageUrl, 'https://images.unsplash.com/photo-earbuds.jpg');
      expect(product.category, 'Audio & Headphones');
      expect(product.rating, 4.8);
      expect(product.stock, 25);
    });
  });
}
