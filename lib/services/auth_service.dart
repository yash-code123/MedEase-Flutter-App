import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<AppUser> login(String username, String password) async {
    final res = await _dio.post(ApiConfig.login, data: {
      'username': username,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final userJson = (data['user'] is Map<String, dynamic>) ? data['user'] as Map<String, dynamic> : data;
    final user = AppUser.fromJson(userJson, token: token);
    await ApiClient.instance.saveToken(token);
    return user;
  }

  /// Patient self-registration — returns the created patient's generated
  /// Patient ID (P-XXXX) so the UI can show it, same as the web signup flow.
  Future<AppUser> signup({
    required String fname,
    required String lname,
    required String phone,
    required String password,
    String? dob,
    String? blood,
  }) async {
    final res = await _dio.post(ApiConfig.signup, data: {
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'password': password,
      if (dob != null) 'dob': dob,
      if (blood != null) 'blood': blood,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final userJson = (data['user'] is Map<String, dynamic>) ? data['user'] as Map<String, dynamic> : data;
    final user = AppUser.fromJson(userJson, token: token);
    if (token.isNotEmpty) await ApiClient.instance.saveToken(token);
    return user;
  }

  Future<void> logout() => ApiClient.instance.clearToken();
}
