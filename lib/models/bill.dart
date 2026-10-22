class Bill {
  final String id;
  final String patientId;
  final String? appointmentId;
  final num amount;
  final String mode; // upi | cash | card
  final String? txnId;
  final String status; // pending | paid
  final String? date;

  Bill({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.amount,
    this.mode = 'upi',
    this.txnId,
    this.status = 'pending',
    this.date,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
        appointmentId: json['appointment_id']?.toString() ?? json['appointmentId']?.toString(),
        amount: (json['amount'] is num) ? json['amount'] as num : num.tryParse('${json['amount']}') ?? 0,
        mode: json['mode']?.toString() ?? 'upi',
        txnId: json['txn_id']?.toString() ?? json['txnId']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        date: json['date']?.toString() ?? json['created_at']?.toString(),
      );
}
