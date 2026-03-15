import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/catalog/domain/product.dart';

void main() {
  group('Product', () {
    test('builds a product from Supabase-style data', () {
      final product = Product.fromJson({
        'id': 'product-1',
        'name': 'Cloud Sofa',
        'description': 'Soft seating for modern spaces.',
        'price': 849.50,
        'image_url': 'https://example.com/cloud-sofa.png',
        'categories': ['Sofas', 'Living Room'],
        'is_active': true,
        'product_models': [
          {
            'id': 'model-1',
            'model_url': 'https://example.com/cloud-sofa.glb',
            'model_type': 'glb',
            'is_primary': true,
          },
        ],
      });

      expect(product.id, 'product-1');
      expect(product.name, 'Cloud Sofa');
      expect(product.price, 849.50);
      expect(product.categories, ['Sofas', 'Living Room']);
      expect(product.modelUrl, 'https://example.com/cloud-sofa.glb');
      expect(product.isActive, isTrue);
      expect(product.primaryModel?.id, 'model-1');
    });

    test('serializes a product payload for writes', () {
      final product = Product(
        id: 'product-2',
        name: 'Glass Table',
        description: 'A compact coffee table.',
        price: 299.00,
        imageUrl: 'https://example.com/glass-table.png',
        categories: const ['Tables'],
        modelUrl: 'https://example.com/glass-table.glb',
        isActive: false,
      );

      expect(product.toJson(), {
        'id': 'product-2',
        'name': 'Glass Table',
        'description': 'A compact coffee table.',
        'price': 299.0,
        'image_url': 'https://example.com/glass-table.png',
        'categories': ['Tables'],
        'is_active': false,
      });
    });
  });
}
