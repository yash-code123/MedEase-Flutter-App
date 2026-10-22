import '../config/api_config.dart';
import '../models/prescription.dart';
import 'api_client.dart';

class PrescriptionService {
  final _dio = ApiClient.instance.dio;

  Future<List<Prescription>> getAll() async {
    final res = await _dio.get(ApiConfig.prescriptions);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Prescription.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Prescription> create(Prescription prescription) async {
    final res = await _dio.post(ApiConfig.prescriptions, data: prescription.toJson());
    return Prescription.fromJson(res.data as Map<String, dynamic>);
  }
}
