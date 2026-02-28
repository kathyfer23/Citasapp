class User {
  final String id;
  final String email;
  final String name;
  final String profession;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.profession,
    this.phone,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profession: json['profession'],
      phone: json['phone'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profession': profession,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
