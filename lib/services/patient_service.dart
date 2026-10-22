import '../config/api_config.dart';
import '../models/patient.dart';
import 'api_client.dart';

class PatientService {
  final _dio = ApiClient.instance.dio;

  Future<List<Patient>> getAll() async {
    final res = await _dio.get(ApiConfig.patients);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Patient> create(Patient patient) async {
    final res = await _dio.post(ApiConfig.patients, data: patient.toJson());
    return Patient.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Patient> getById(String id) async {
    final res = await _dio.get('${ApiConfig.patients}/$id');
    return Patient.fromJson(res.data as Map<String, dynamic>);
  }
}
