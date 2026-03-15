import '../domain/product.dart';

class ProductRepository {
  // Use real public GLB models for testing
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Eames Lounge Chair',
      description:
          'The Eames Lounge Chair and Ottoman are furnishings made of molded plywood and leather, designed by Charles and Ray Eames.',
      price: 4999.00,
      imageUrl:
          'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&q=80&w=600',
      categories: ['Chairs', 'Living Room'],
      modelUrl:
          'https://modelviewer.dev/shared-assets/models/Astronaut.glb', // Placeholder real model
    ),
    Product(
      id: '2',
      name: 'Noguchi Table',
      description:
          'A piece of modern furniture first produced in the mid-20th century. Introduced by Herman Miller in 1947.',
      price: 1250.00,
      imageUrl:
          'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&q=80&w=600',
      categories: ['Tables', 'Living Room'],
      modelUrl:
          'https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb', // Placeholder real model
    ),
    Product(
      id: '4',
      name: 'Tufty-Time Sofa',
      description:
          'Patricia Urquiola designed Tufty-Time, an informal seating system that combines comfort with a modular spirit.',
      price: 3200.00,
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=600',
      categories: ['Sofas', 'Living Room'],
      modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    ),
  ];

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _products;
  }

  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _products.firstWhere(
      (p) => p.id == id,
      orElse: () => _products.first,
    );
  }
}
