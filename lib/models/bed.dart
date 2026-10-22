class Bed {
  final String id;
  final String ward;
  final String status; // vacant | occupied
  final String? patientId;

  Bed({required this.id, required this.ward, this.status = 'vacant', this.patientId});

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
        id: json['id']?.toString() ?? '',
        ward: json['ward']?.toString() ?? '',
        status: json['status']?.toString() ?? 'vacant',
        patientId: json['patient_id']?.toString() ?? json['patientId']?.toString(),
      );
}
