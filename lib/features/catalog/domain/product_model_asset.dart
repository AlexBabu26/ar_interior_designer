class ProductModelAsset {
  const ProductModelAsset({
    required this.id,
    required this.modelUrl,
    required this.modelType,
    required this.isPrimary,
  });

  final String id;
  final String modelUrl;
  final String modelType;
  final bool isPrimary;

  factory ProductModelAsset.fromJson(Map<String, dynamic> json) {
    return ProductModelAsset(
      id: json['id'] as String? ?? '',
      modelUrl: json['model_url'] as String? ?? '',
      modelType: json['model_type'] as String? ?? 'glb',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}
