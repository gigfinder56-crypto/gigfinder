class ChatMessage {
  final String id;
  final String userId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'sender_id': senderId,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? json['userId'] ?? '',
    senderId: json['sender_id'] ?? json['senderId'] ?? '',
    message: json['message'] ?? '',
    timestamp: _parseDateTime(json['timestamp']),
    isRead: json['is_read'] ?? json['isRead'] ?? false,
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? senderId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) => ChatMessage(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    senderId: senderId ?? this.senderId,
    message: message ?? this.message,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
  );
}
