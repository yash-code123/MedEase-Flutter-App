class QueueToken {
  final String id; // T-XXX
  final String appointmentId;
  final String patientId;
  final String? patientName;
  final String? doctorName; // backend field is doctor_name (a string), not doctor_id
  final String? dept;
  final String priority; // 'Normal' or 'Emergency' — backend sends a string, not a number
  final String status; // 'Waiting' | 'Called' | 'Done' (capitalized, per backend)

  QueueToken({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    this.patientName,
    this.doctorName,
    this.dept,
    this.priority = 'Normal',
    this.status = 'Waiting',
  });

  factory QueueToken.fromJson(Map<String, dynamic> json) => QueueToken(
    id: json['id']?.toString() ?? '',
    appointmentId: json['appointment_id']?.toString() ?? json['appointmentId']?.toString() ?? '',
    patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
    patientName: json['patient_name']?.toString() ?? json['patientName']?.toString(),
    doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString(),
    dept: json['dept']?.toString(),
    priority: json['priority']?.toString() ?? 'Normal',
    status: json['status']?.toString() ?? 'Waiting',
  );
}

/// Small helper used everywhere in the app to compare status strings
/// without caring about the backend's capitalization ("Paid" vs "paid").
bool statusIs(String? status, String expected) =>
    (status ?? '').trim().toLowerCase() == expected.trim().toLowerCase();