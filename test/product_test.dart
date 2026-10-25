import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/products/domain/models/product.dart';

void main() {
  group('Product', () {
    test('parses product JSON correctly', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Headphones',
        'description': 'Wireless headphones',
        'price': 2499,
        'image': '',
        'category': 'Electronics',
        'rating': {
          'rate': 4.5,
        },
        'stock': 10,
      });

      expect(product.id, '1');
      expect(product.title, 'Headphones');
      expect(product.price, 2499.0);
      expect(product.rating, 4.5);
      expect(product.stock, 10);
    });
  });
}
