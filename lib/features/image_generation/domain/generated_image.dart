/// A saved generated image record (prompt + local path).
class GeneratedImage {
  const GeneratedImage({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.imagePath,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String prompt;
  final String imagePath;
  final DateTime createdAt;

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      prompt: json['prompt'] as String,
      imagePath: json['image_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
