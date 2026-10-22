class Patient {
  final String id; // P-XXXX
  final String fname;
  final String lname;
  final String? dob;
  final String? blood;
  final String? phone;
  final String? allergies;

  Patient({
    required this.id,
    required this.fname,
    required this.lname,
    this.dob,
    this.blood,
    this.phone,
    this.allergies,
  });

  String get fullName => '$fname $lname'.trim();

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id']?.toString() ?? '',
        fname: json['fname']?.toString() ?? '',
        lname: json['lname']?.toString() ?? '',
        dob: json['dob']?.toString(),
        blood: json['blood']?.toString(),
        phone: json['phone']?.toString(),
        allergies: json['allergies']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'fname': fname,
        'lname': lname,
        if (dob != null) 'dob': dob,
        if (blood != null) 'blood': blood,
        if (phone != null) 'phone': phone,
        if (allergies != null) 'allergies': allergies,
      };
}
