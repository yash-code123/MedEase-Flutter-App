import '../config/api_config.dart';
import '../models/bed.dart';
import 'api_client.dart';

class BedService {
  final _dio = ApiClient.instance.dio;

  Future<List<Bed>> getAll() async {
    final res = await _dio.get(ApiConfig.beds);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Bed.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, String status, {String? patientId}) async {
    await _dio.put(ApiConfig.bedItem(id), data: {
      'status': status,
      if (patientId != null) 'patient_id': patientId,
    });
  }

  Future<void> updateBed(String id, String status, String? patientId) async {
    await _dio.put(ApiConfig.bedItem(id), data: {
      'status': status,
      'patient_id': patientId,
    });
  }
}
