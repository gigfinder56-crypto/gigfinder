class Opportunity {
  final String id;
  final String title;
  final String category;
  final String description;
  final String company;
  final String location;
  final List<String> requiredSkills;
  final String salary;
  final String duration;
  final DateTime postedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Opportunity({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.company,
    required this.location,
    this.requiredSkills = const [],
    required this.salary,
    required this.duration,
    required this.postedDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'company': company,
    'location': location,
    'required_skills': requiredSkills,
    'salary': salary,
    'duration': duration,
    'posted_date': postedDate.toIso8601String(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    category: json['category'] ?? '',
    description: json['description'] ?? '',
    company: json['company'] ?? '',
    location: json['location'] ?? '',
    requiredSkills: List<String>.from(json['required_skills'] ?? json['requiredSkills'] ?? []),
    salary: json['salary'] ?? '',
    duration: json['duration'] ?? '',
    postedDate: _parseDateTime(json['posted_date'] ?? json['postedDate']),
    isActive: json['is_active'] ?? json['isActive'] ?? true,
    createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Opportunity copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? company,
    String? location,
    List<String>? requiredSkills,
    String? salary,
    String? duration,
    DateTime? postedDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Opportunity(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    description: description ?? this.description,
    company: company ?? this.company,
    location: location ?? this.location,
    requiredSkills: requiredSkills ?? this.requiredSkills,
    salary: salary ?? this.salary,
    duration: duration ?? this.duration,
    postedDate: postedDate ?? this.postedDate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
