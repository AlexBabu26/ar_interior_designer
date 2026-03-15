import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/catalog/domain/product.dart';
import 'package:myapp/features/cart/domain/cart_item.dart';

void main() {
  group('CartItem', () {
    test('builds from json with nested products', () {
      final item = CartItem.fromJson({
        'quantity': 2,
        'products': {
          'id': 'prod-1',
          'name': 'Cloud Sofa',
          'description': 'Soft seating.',
          'price': 849.50,
          'image_url': 'https://example.com/sofa.png',
          'categories': ['Sofas'],
          'is_active': true,
          'product_models': [],
        },
      });

      expect(item.quantity, 2);
      expect(item.product.id, 'prod-1');
      expect(item.product.name, 'Cloud Sofa');
      expect(item.product.price, 849.50);
    });

    test('builds from json with product key (alternative)', () {
      final item = CartItem.fromJson({
        'quantity': 1,
        'product': {
          'id': 'prod-2',
          'name': 'Glass Table',
          'description': 'A table.',
          'price': 299.00,
          'image_url': 'https://example.com/table.png',
          'categories': ['Tables'],
          'is_active': true,
          'product_models': [],
        },
      });

      expect(item.quantity, 1);
      expect(item.product.name, 'Glass Table');
    });

    test('copyWith updates quantity', () {
      final product = Product(
        id: 'p1',
        name: 'Test',
        description: 'Desc',
        price: 10,
        imageUrl: 'https://x/x.png',
        categories: const [],
        modelUrl: 'https://x/x.glb',
      );
      final item = CartItem(product: product, quantity: 1);
      final updated = item.copyWith(quantity: 3);

      expect(updated.quantity, 3);
      expect(updated.product, same(product));
    });
  });
}
