class Application {
  final String id;
  final String userId;
  final String opportunityId;
  final String status;
  final DateTime appliedDate;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.userId,
    required this.opportunityId,
    this.status = 'pending',
    required this.appliedDate,
    this.adminNotes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'opportunity_id': opportunityId,
    'status': status,
    'applied_date': appliedDate.toIso8601String(),
    'admin_notes': adminNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? json['userId'] ?? '',
    opportunityId: json['opportunity_id'] ?? json['opportunityId'] ?? '',
    status: json['status'] ?? 'pending',
    appliedDate: _parseDateTime(json['applied_date'] ?? json['appliedDate']),
    adminNotes: json['admin_notes'] ?? json['adminNotes'] ?? '',
    createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Application copyWith({
    String? id,
    String? userId,
    String? opportunityId,
    String? status,
    DateTime? appliedDate,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Application(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    opportunityId: opportunityId ?? this.opportunityId,
    status: status ?? this.status,
    appliedDate: appliedDate ?? this.appliedDate,
    adminNotes: adminNotes ?? this.adminNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
