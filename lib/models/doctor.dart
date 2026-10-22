class Doctor {
  final String id; // D-XXX
  final String name;
  final String dept;
  final String? qualification;
  final num fee;
  final String status; // 'Active' | 'Inactive' — exact DB enum values

  Doctor({
    required this.id,
    required this.name,
    required this.dept,
    this.qualification,
    this.fee = 0,
    this.status = 'Active',
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    dept: json['dept']?.toString() ?? '',
    qualification: json['qual']?.toString() ?? json['qualification']?.toString(),
    fee: (json['fee'] is num) ? json['fee'] as num : num.tryParse('${json['fee']}') ?? 0,
    status: json['status']?.toString() ?? 'Active',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'dept': dept,
    if (qualification != null) 'qual': qualification,
    'fee': fee,
    'status': status,
  };
}