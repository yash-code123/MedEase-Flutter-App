import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/doctor.dart';
import '../../services/doctor_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  final _service = DoctorService();
  late Future<List<Doctor>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _refresh() { setState(() { _future = _service.getAll(); }); }

  void _showCredentialsDialog(String username, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Doctor login created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share these with the doctor — this password is auto-generated and won\'t be shown again.'),
            const SizedBox(height: 16),
            SelectableText('Username: $username', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText('Password: $password', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _openAddDoctorSheet() async {
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final qualCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add doctor', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name (e.g. Dr. Rajan Iyer)')),
                const SizedBox(height: 12),
                TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
                const SizedBox(height: 12),
                TextField(controller: qualCtrl, decoration: const InputDecoration(labelText: 'Qualification')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (last 4 digits become part of the password)'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: feeCtrl, decoration: const InputDecoration(labelText: 'Consultation fee (₹)'), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (nameCtrl.text.trim().isEmpty || deptCtrl.text.trim().isEmpty) return;
                      setModalState(() => saving = true);
                      try {
                        final result = await _service.createWithCredentials(
                          name: nameCtrl.text.trim(),
                          dept: deptCtrl.text.trim(),
                          qualification: qualCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          fee: num.tryParse(feeCtrl.text) ?? 0,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _refresh();
                        if (mounted) _showCredentialsDialog(result.$1, result.$2);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
                          );
                        }
                      } finally {
                        setModalState(() => saving = false);
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add doctor & auto-create login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDoctorSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add doctor'),
      ),
      body: FutureBuilder<List<Doctor>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading doctors…');
          }
          if (snapshot.hasError) {
            return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
          }
          final doctors = snapshot.data!;
          if (doctors.isEmpty) {
            return const EmptyState(icon: Icons.medical_services_outlined, title: 'No doctors yet', subtitle: 'Tap "Add doctor" to onboard one.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: doctors.length,
            itemBuilder: (context, i) {
              final d = doctors[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: MedEaseColors.primaryLight, child: Icon(Icons.person, color: MedEaseColors.primary)),
                  title: Text(d.name),
                  subtitle: Text('${d.dept} · ₹${d.fee}'),
                  trailing: StatusBadge(status: d.status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}