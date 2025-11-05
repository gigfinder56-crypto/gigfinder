class Experience {
  final String id;
  final String userId;
  final String userName;
  final String opportunityId;
  final String opportunityTitle;
  final String title;
  final String content;
  final double rating;
  final DateTime postedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Experience({
    required this.id,
    required this.userId,
    required this.userName,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.title,
    required this.content,
    required this.rating,
    required this.postedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'opportunity_id': opportunityId,
    'opportunity_title': opportunityTitle,
    'title': title,
    'content': content,
    'rating': rating,
    'posted_date': postedDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? json['userId'] ?? '',
    userName: json['user_name'] ?? json['userName'] ?? '',
    opportunityId: json['opportunity_id'] ?? json['opportunityId'] ?? '',
    opportunityTitle: json['opportunity_title'] ?? json['opportunityTitle'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    rating: (json['rating'] ?? 0.0).toDouble(),
    postedDate: _parseDateTime(json['posted_date'] ?? json['postedDate']),
    createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Experience copyWith({
    String? id,
    String? userId,
    String? userName,
    String? opportunityId,
    String? opportunityTitle,
    String? title,
    String? content,
    double? rating,
    DateTime? postedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Experience(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    opportunityId: opportunityId ?? this.opportunityId,
    opportunityTitle: opportunityTitle ?? this.opportunityTitle,
    title: title ?? this.title,
    content: content ?? this.content,
    rating: rating ?? this.rating,
    postedDate: postedDate ?? this.postedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
