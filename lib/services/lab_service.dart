import '../config/api_config.dart';
import '../models/lab_order.dart';
import 'api_client.dart';

class LabService {
  final _dio = ApiClient.instance.dio;

  Future<List<LabOrder>> getAll() async {
    final res = await _dio.get(ApiConfig.lab);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => LabOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LabOrder> order(LabOrder labOrder) async {
    final res = await _dio.post(ApiConfig.lab, data: labOrder.toJson());
    return LabOrder.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> uploadResult(String id, String result) async {
    await _dio.patch(ApiConfig.labResult(id), data: {'result': result});
  }
}
