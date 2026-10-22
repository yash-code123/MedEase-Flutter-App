import '../config/api_config.dart';
import '../models/bill.dart';
import 'api_client.dart';

class BillingService {
  final _dio = ApiClient.instance.dio;

  Future<List<Bill>> getAll() async {
    final res = await _dio.get(ApiConfig.billing);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bill> create({
    required String patientId,
    String? appointmentId,
    required num amount,
    String mode = 'upi',
    String? txnId,
  }) async {
    final res = await _dio.post(ApiConfig.billing, data: {
      'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'amount': amount,
      'mode': mode,
      if (txnId != null) 'txn_id': txnId,
    });
    return Bill.fromJson(res.data as Map<String, dynamic>);
  }
}
