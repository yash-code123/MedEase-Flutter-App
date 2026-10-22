import '../config/api_config.dart';
import '../models/doctor.dart';
import 'api_client.dart';

class DoctorService {
  final _dio = ApiClient.instance.dio;

  Future<List<Doctor>> getAll() async {
    final res = await _dio.get(ApiConfig.doctors);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Doctor> create(Doctor doctor) async {
    final res = await _dio.post(ApiConfig.doctors, data: doctor.toJson());
    final data = res.data as Map<String, dynamic>;
    final doctorJson = (data['doctor'] is Map<String, dynamic>) ? data['doctor'] as Map<String, dynamic> : data;
    return Doctor.fromJson(doctorJson);
  }

  /// Same as create(), but also returns the auto-generated (username, password)
  /// your backend sends back in the response — needed since each doctor gets
  /// a UNIQUE password (based on their phone number), not a shared default.
  Future<(String, String)> createWithCredentials({
    required String name,
    required String dept,
    String? qualification,
    String? phone,
    num fee = 0,
  }) async {
    final res = await _dio.post(ApiConfig.doctors, data: {
      'name': name,
      'dept': dept,
      if (qualification != null) 'qualification': qualification,
      if (phone != null) 'phone': phone,
      'fee': fee,
      'status': 'Active',
    });
    final data = res.data as Map<String, dynamic>;
    final username = data['username']?.toString() ?? '';
    final password = data['tempPassword']?.toString() ?? '';
    return (username, password);
  }
}