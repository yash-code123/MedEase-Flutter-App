class AppUser {
  final String id;
  final String username;
  final String role; // admin | superadmin | doctor | patient
  final String refId; // links to patients.id or doctors.id
  final String token;

  AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.refId,
    required this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, {String token = ''}) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'patient',
      refId: json['ref_id']?.toString() ?? json['refId']?.toString() ?? '',
      token: token.isNotEmpty ? token : (json['token']?.toString() ?? ''),
    );
  }

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'username': username,
        'role': role,
        'ref_id': refId,
        'token': token,
      };
}
