import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
  }

  final _authService = AuthService();

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;
  bool _warmingUp = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get warmingUp => _warmingUp;

  /// Fires a lightweight request at app launch to wake a sleeping Render
  /// free-tier backend BEFORE the user tries to log in, so the real login
  /// request is less likely to time out. Safe to ignore failures here —
  /// the actual login call will still work, just slower, if this fails.
  Future<void> warmUpBackend() async {
    _warmingUp = true;
    notifyListeners();
    try {
      await ApiClient.instance.dio.get(
        'https://medease-patient-and-finance-system.onrender.com/api',
        options: Options(
          sendTimeout: const Duration(seconds: 50),
          receiveTimeout: const Duration(seconds: 50),
        ),
      );
    } catch (_) {
      // Ignore — this is just a warm-up ping, not a critical request.
    } finally {
      _warmingUp = false;
      notifyListeners();
    }
  }

  Future<void> bootstrap() async {
    final token = await ApiClient.instance.readToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(username, password);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _error = describeDioError(e);
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String fname,
    required String lname,
    required String phone,
    required String password,
    String? dob,
    String? blood,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signup(
        fname: fname,
        lname: lname,
        phone: phone,
        password: password,
        dob: dob,
        blood: blood,
      );
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _error = describeDioError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _handleUnauthorized() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}