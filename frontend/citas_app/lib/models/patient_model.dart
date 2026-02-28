class Patient {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime? birthDate;
  final String? notes;
  final bool isNew;
  final DateTime createdAt;
  final int? appointmentsCount;

  Patient({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.birthDate,
    this.notes,
    this.isNew = true,
    required this.createdAt,
    this.appointmentsCount,
  });

  String get fullName => '$firstName $lastName';

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate']) 
          : null,
      notes: json['notes'],
      isNew: json['isNew'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      appointmentsCount: json['_count']?['appointments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String(),
      'notes': notes,
    };
  }
}
