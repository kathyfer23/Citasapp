import 'patient_model.dart';

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled;

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}

class Appointment {
  final String id;
  final DateTime dateTime;
  final int duration;
  final AppointmentStatus status;
  final String? notes;
  final bool reminderSent;
  final bool whatsappReminderSent;
  final String? transcription;
  final String? aiSummary;
  final DateTime createdAt;
  final String patientId;
  final Patient? patient;

  Appointment({
    required this.id,
    required this.dateTime,
    this.duration = 30,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.reminderSent = false,
    this.whatsappReminderSent = false,
    this.transcription,
    this.aiSummary,
    required this.createdAt,
    required this.patientId,
    this.patient,
  });

  DateTime get endTime => dateTime.add(Duration(minutes: duration));

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      dateTime: DateTime.parse(json['dateTime']),
      duration: json['duration'] ?? 30,
      status: AppointmentStatus.fromString(json['status'] ?? 'scheduled'),
      notes: json['notes'],
      reminderSent: json['reminderSent'] ?? false,
      whatsappReminderSent: json['whatsappReminderSent'] ?? false,
      transcription: json['transcription'],
      aiSummary: json['aiSummary'],
      createdAt: DateTime.parse(json['createdAt']),
      patientId: json['patientId'],
      patient: json['patient'] != null
          ? Patient.fromJson(json['patient'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'notes': notes,
    };
  }

  Appointment copyWith({
    String? id,
    DateTime? dateTime,
    int? duration,
    AppointmentStatus? status,
    String? notes,
    bool? reminderSent,
    bool? whatsappReminderSent,
    String? transcription,
    String? aiSummary,
    String? patientId,
    Patient? patient,
  }) {
    return Appointment(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderSent: reminderSent ?? this.reminderSent,
      whatsappReminderSent: whatsappReminderSent ?? this.whatsappReminderSent,
      transcription: transcription ?? this.transcription,
      aiSummary: aiSummary ?? this.aiSummary,
      createdAt: createdAt,
      patientId: patientId ?? this.patientId,
      patient: patient ?? this.patient,
    );
  }
}
