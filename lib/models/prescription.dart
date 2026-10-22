class Medicine {
  final String name;
  final String dosage;
  final String duration;

  Medicine({required this.name, required this.dosage, required this.duration});

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        name: json['name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'dosage': dosage, 'duration': duration};
}

class Vitals {
  final String? bp;
  final String? pulse;
  final String? temp;
  final String? spo2;
  final String? bmi;

  Vitals({this.bp, this.pulse, this.temp, this.spo2, this.bmi});

  factory Vitals.fromJson(Map<String, dynamic> json) => Vitals(
        bp: json['bp']?.toString(),
        pulse: json['pulse']?.toString(),
        temp: json['temp']?.toString(),
        spo2: json['spo2']?.toString(),
        bmi: json['bmi']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (bp != null) 'bp': bp,
        if (pulse != null) 'pulse': pulse,
        if (temp != null) 'temp': temp,
        if (spo2 != null) 'spo2': spo2,
        if (bmi != null) 'bmi': bmi,
      };
}

class Prescription {
  final String id;
  final String patientId;
  final String? doctorId;
  final String diagnosis;
  final List<Medicine> medicines;
  final Vitals? vitals;
  final String? date;

  Prescription({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.diagnosis,
    required this.medicines,
    this.vitals,
    this.date,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final medsRaw = json['medicines'];
    final meds = <Medicine>[];
    if (medsRaw is List) {
      for (final m in medsRaw) {
        if (m is Map<String, dynamic>) meds.add(Medicine.fromJson(m));
      }
    }
    return Prescription(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? json['doctorId']?.toString(),
      diagnosis: json['diagnosis']?.toString() ?? '',
      medicines: meds,
      vitals: json['vitals'] is Map<String, dynamic> ? Vitals.fromJson(json['vitals']) : null,
      date: json['date']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'diagnosis': diagnosis,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        if (vitals != null) 'vitals': vitals!.toJson(),
      };
}
