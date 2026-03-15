import 'product_model_asset.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categories,
    required this.modelUrl,
    this.isActive = true,
    this.models = const <ProductModelAsset>[],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> categories;
  final String modelUrl;
  final bool isActive;
  final List<ProductModelAsset> models;

  ProductModelAsset? get primaryModel {
    if (models.isEmpty) {
      return null;
    }

    return models.firstWhere(
      (model) => model.isPrimary,
      orElse: () => models.first,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawModels = (json['product_models'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => ProductModelAsset.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final primaryModel = rawModels.cast<ProductModelAsset?>().firstWhere(
      (model) => model?.isPrimary ?? false,
      orElse: () => rawModels.isEmpty ? null : rawModels.first,
    );

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      modelUrl: primaryModel?.modelUrl ?? '',
      isActive: json['is_active'] as bool? ?? true,
      models: rawModels,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'categories': categories,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? categories,
    String? modelUrl,
    bool? isActive,
    List<ProductModelAsset>? models,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      modelUrl: modelUrl ?? this.modelUrl,
      isActive: isActive ?? this.isActive,
      models: models ?? this.models,
    );
  }
}
