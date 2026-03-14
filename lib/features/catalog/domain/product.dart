class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> categories;
  final String modelUrl; // Placeholder for AR model

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categories,
    required this.modelUrl,
  });
}
