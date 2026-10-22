import '../config/api_config.dart';
import '../models/medicine_stock.dart';
import 'api_client.dart';

class PharmacyService {
  final _dio = ApiClient.instance.dio;

  Future<List<MedicineStock>> getAll() async {
    final res = await _dio.get(ApiConfig.pharmacy);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => MedicineStock.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStock(String id, int quantity) async {
    await _dio.put(ApiConfig.pharmacyItem(id), data: {'quantity': quantity});
  }
}
