class StudentInfo {
  final String year;
  final String college;
  final String branch;

  StudentInfo({required this.year, required this.college, required this.branch});

  Map<String, dynamic> toJson() => {
    'year': year,
    'college': college,
    'branch': branch,
  };

  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
    year: json['year'] ?? '',
    college: json['college'] ?? '',
    branch: json['branch'] ?? '',
  );
}

class EmployeeInfo {
  final String company;
  final String role;
  final int yearsOfExperience;

  EmployeeInfo({required this.company, required this.role, required this.yearsOfExperience});

  Map<String, dynamic> toJson() => {
    'company': company,
    'role': role,
    'yearsOfExperience': yearsOfExperience,
  };

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) => EmployeeInfo(
    company: json['company'] ?? '',
    role: json['role'] ?? '',
    yearsOfExperience: json['yearsOfExperience'] ?? 0,
  );
}

class User {
  final String id;
  final String email;
  final String name;
  final int age;
  final String profilePhotoPath;
  final String mobileNumber;
  final List<String> skills;
  final List<String> interests;
  final String resumePath;
  final String role;
  final String location;
  final StudentInfo? studentInfo;
  final EmployeeInfo? employeeInfo;
  final String others;
  final bool isProfileComplete;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.name = '',
    this.age = 0,
    this.profilePhotoPath = '',
    this.mobileNumber = '',
    this.skills = const [],
    this.interests = const [],
    this.resumePath = '',
    this.role = '',
    this.location = '',
    this.studentInfo,
    this.employeeInfo,
    this.others = '',
    this.isProfileComplete = false,
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'age': age,
    'profile_photo_path': profilePhotoPath,
    'mobile_number': mobileNumber,
    'skills': skills,
    'interests': interests,
    'resume_path': resumePath,
    'role': role,
    'location': location,
    'student_info': studentInfo?.toJson(),
    'employee_info': employeeInfo?.toJson(),
    'others': others,
    'is_profile_complete': isProfileComplete,
    'is_admin': isAdmin,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    name: json['name'] ?? '',
    age: json['age'] ?? 0,
    profilePhotoPath: json['profile_photo_path'] ?? json['profilePhotoPath'] ?? '',
    mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
    skills: List<String>.from(json['skills'] ?? []),
    interests: List<String>.from(json['interests'] ?? []),
    resumePath: json['resume_path'] ?? json['resumePath'] ?? '',
    role: json['role'] ?? '',
    location: json['location'] ?? '',
    studentInfo: json['student_info'] != null ? StudentInfo.fromJson(json['student_info']) : 
                 json['studentInfo'] != null ? StudentInfo.fromJson(json['studentInfo']) : null,
    employeeInfo: json['employee_info'] != null ? EmployeeInfo.fromJson(json['employee_info']) : 
                  json['employeeInfo'] != null ? EmployeeInfo.fromJson(json['employeeInfo']) : null,
    others: json['others'] ?? '',
    isProfileComplete: json['is_profile_complete'] ?? json['isProfileComplete'] ?? false,
    isAdmin: json['is_admin'] ?? json['isAdmin'] ?? false,
    createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
  );

  User copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? profilePhotoPath,
    String? mobileNumber,
    List<String>? skills,
    List<String>? interests,
    String? resumePath,
    String? role,
    String? location,
    StudentInfo? studentInfo,
    EmployeeInfo? employeeInfo,
    String? others,
    bool? isProfileComplete,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    age: age ?? this.age,
    profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    skills: skills ?? this.skills,
    interests: interests ?? this.interests,
    resumePath: resumePath ?? this.resumePath,
    role: role ?? this.role,
    location: location ?? this.location,
    studentInfo: studentInfo ?? this.studentInfo,
    employeeInfo: employeeInfo ?? this.employeeInfo,
    others: others ?? this.others,
    isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    isAdmin: isAdmin ?? this.isAdmin,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
