class FurnitureModificationMessage {
  const FurnitureModificationMessage({
    required this.id,
    required this.modificationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderDisplayName,
  });

  final String id;
  final String modificationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String? senderDisplayName;

  factory FurnitureModificationMessage.fromJson(Map<String, dynamic> json) {
    return FurnitureModificationMessage(
      id: json['id'] as String,
      modificationId: json['modification_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderDisplayName: json['sender_display_name'] as String?,
    );
  }
}
