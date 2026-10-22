import '../config/api_config.dart';
import '../models/token_model.dart';
import 'api_client.dart';

class TokenService {
  final _dio = ApiClient.instance.dio;

  Future<List<QueueToken>> getAll() async {
    final res = await _dio.get(ApiConfig.tokens);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => QueueToken.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await _dio.patch(ApiConfig.tokenStatus(id), data: {'status': status});
  }
}
