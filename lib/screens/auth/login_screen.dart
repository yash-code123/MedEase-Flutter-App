import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_home.dart';
import '../doctor/doctor_shell.dart';
import '../patient/patient_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      final user = auth.user!;
      Widget dest = const PatientShell();
      if (user.isAdmin) dest = const AdminHome();
      if (user.isDoctor) dest = const DoctorShell();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => dest));
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: MedEaseColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.warmingUp) {
      // optional: you can show a small banner here, e.g.
      // "Waking up the server — this can take up to a minute on first use."
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MedEaseColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: MedEaseColors.primary, size: 28),
                ),
                const SizedBox(height: 20),
                Text('Welcome back', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  'Sign in to MedEase — works for Patients, Doctors, and Admins.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username or Patient ID',
                    hintText: 'admin, dr.kavitha.rao, or P-1001',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text("New patient? Create an account"),
                  ),
                ),
                const SizedBox(height: 24),
                _DemoCredentialsCard(onFill: (u, p) {
                  _usernameCtrl.text = u;
                  _passwordCtrl.text = p;
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoCredentialsCard extends StatelessWidget {
  final void Function(String username, String password) onFill;
  const _DemoCredentialsCard({required this.onFill});

  @override
  Widget build(BuildContext context) {
    final demos = const [
      ('Admin', 'admin', 'admin123'),
      ('Doctor', 'dr.kavitha.rao', 'doc123'),
      ('Patient', 'P-1001', 'patient123'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Try a demo account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final d in demos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: MedEaseTheme.roleColor(d.$1).withValues(alpha: 0.15),
                  child: Text(d.$1[0], style: TextStyle(color: MedEaseTheme.roleColor(d.$1), fontSize: 12)),
                ),
                title: Text(d.$1, style: const TextStyle(fontSize: 13)),
                subtitle: Text('${d.$2} / ${d.$3}', style: const TextStyle(fontSize: 12)),
                trailing: TextButton(
                  onPressed: () => onFill(d.$2, d.$3),
                  child: const Text('Use'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
