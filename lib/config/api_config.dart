/// Central place for backend configuration.
///
/// This app talks to the SAME backend + database as the MedEase website.
/// Confirmed live URL from the Render dashboard:
/// https://medease-patient-and-finance-system.onrender.com
class ApiConfig {
  ApiConfig._();

  // Trailing slash on baseUrl + no leading slash on paths below, so Dio's
  // URI-merge logic appends correctly instead of dropping the "/api" segment.
  static const String baseUrl = String.fromEnvironment(
    'MEDEASE_API_BASE_URL',
    defaultValue: 'https://medease-patient-and-finance-system.onrender.com/api/',
  );

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String login = 'auth/login';
  static const String signup = 'auth/signup';

  static const String patients = 'patients';
  static const String doctors = 'doctors';
  static const String appointments = 'appointments';
  static const String tokens = 'tokens';
  static const String prescriptions = 'prescriptions';
  static const String lab = 'lab';
  static const String billing = 'billing';
  static const String pharmacy = 'pharmacy';
  static const String beds = 'beds';

  static String appointmentStatus(String id) => '$appointments/$id/status';
  static String tokenStatus(String id) => '$tokens/$id/status';
  static String labResult(String id) => '$lab/$id/result';
  static String pharmacyItem(String id) => '$pharmacy/$id';
  static String bedItem(String id) => '$beds/$id';
}