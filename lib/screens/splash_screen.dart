import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'admin/admin_home.dart';
import 'doctor/doctor_shell.dart';
import 'patient/patient_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    auth.warmUpBackend(); // fire-and-forget: wakes a sleeping Render backend early
    await auth.bootstrap();
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      // Note: on cold start we only know a token exists, not the role yet
      // if the app was killed. Login screen re-derives role on fresh login;
      // for a persisted session we route through a lightweight role check.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _RoleRouter()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MedEaseColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_rounded, color: Colors.white, size: 56),
            SizedBox(height: 16),
            Text(
              'MedEase',
              style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Serif'),
            ),
            SizedBox(height: 8),
            Text(
              'Hospital Management, simplified',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Routes a restored session to the correct role shell based on stored user.
/// If role info isn't available (e.g. app was force-closed), falls back to login.
class _RoleRouter extends StatelessWidget {
  const _RoleRouter();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoginScreen();
    if (user.isAdmin) return const AdminHome();
    if (user.isDoctor) return const DoctorShell();
    return const PatientShell();
  }
}
