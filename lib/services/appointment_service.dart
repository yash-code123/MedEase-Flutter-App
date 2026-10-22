import '../config/api_config.dart';
import '../models/appointment.dart';
import 'api_client.dart';

class AppointmentService {
  final _dio = ApiClient.instance.dio;

  Future<List<Appointment>> getAll() async {
    final res = await _dio.get(ApiConfig.appointments);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Books an appointment. Backend auto-creates the queue token + bill,
  /// mirroring the 4-step booking wizard on web.
  Future<Appointment> book(Appointment appointment) async {
    final res = await _dio.post(ApiConfig.appointments, data: appointment.toJson());
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, String status) async {
    await _dio.patch(ApiConfig.appointmentStatus(id), data: {'status': status});
  }
}
