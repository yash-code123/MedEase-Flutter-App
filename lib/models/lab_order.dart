class LabOrder {
  final String id;
  final String patientId;
  final String test;
  final String priority; // routine | urgent
  final String status; // pending | completed
  final String? result;

  LabOrder({
    required this.id,
    required this.patientId,
    required this.test,
    this.priority = 'routine',
    this.status = 'pending',
    this.result,
  });

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
        test: json['test']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'routine',
        status: json['status']?.toString() ?? 'pending',
        result: json['result']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'test': test,
        'priority': priority,
      };
}
