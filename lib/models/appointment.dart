class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String? patientName;
  final String? doctorName;
  final String? department;
  final String date; // yyyy-MM-dd
  final String time;
  final num fee;
  final String payStatus;
  final String status;
  final String type; // 'Normal' or 'Emergency'
  final String? phone;
  final String payMode; // 'cash' | 'upi' | 'card'
  final String? txnId;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.patientName,
    this.doctorName,
    this.department,
    required this.date,
    required this.time,
    this.fee = 0,
    this.payStatus = 'Pending',
    this.status = 'Confirmed',
    this.type = 'New Visit',
    this.phone,
    this.payMode = 'upi',
    this.txnId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id']?.toString() ?? '',
    patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
    doctorId: json['doctor_id']?.toString() ?? json['doctorId']?.toString() ?? '',
    patientName: json['patient_name']?.toString() ?? json['patientName']?.toString(),
    doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString(),
    department: json['dept']?.toString() ?? json['department']?.toString(),
    date: json['date']?.toString() ?? '',
    time: json['time']?.toString() ?? '',
    fee: (json['fee'] is num) ? json['fee'] as num : num.tryParse('${json['fee']}') ?? 0,
    payStatus: json['pay_status']?.toString() ?? json['payStatus']?.toString() ?? 'Pending',
    status: json['status']?.toString() ?? 'Confirmed',
    type: json['type']?.toString() ?? 'Normal',
    phone: json['phone']?.toString(),
    payMode: json['pay_mode']?.toString() ?? 'upi',
    txnId: json['txn_id']?.toString(),
  );

  // Everything the backend's POST /appointments route actually reads
  // from req.body — sending less than this means doctor_name/patient_name
  // end up null on the created token and bill.
  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'patient_name': patientName,
    'doctor_id': doctorId,
    'doctor_name': doctorName,
    'dept': department,
    'date': date,
    'time': time,
    'type': type,
    'phone': phone,
    'fee': fee,
    'pay_mode': payMode,
    if (txnId != null) 'txn_id': txnId,
  };
}