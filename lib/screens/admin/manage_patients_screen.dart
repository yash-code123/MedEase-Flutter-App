import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/patient.dart';
import '../../services/patient_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

/// Patient registration & records management for the front desk.
class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({super.key});

  @override
  State<ManagePatientsScreen> createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  final _service = PatientService();
  late Future<List<Patient>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _refresh() { setState(() { _future = _service.getAll(); }); }

  Future<void> _openAddPatientSheet() async {
    final fnameCtrl = TextEditingController();
    final lnameCtrl = TextEditingController();
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
                Text('Register patient', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextField(controller: fnameCtrl, decoration: const InputDecoration(labelText: 'First name')),
                const SizedBox(height: 12),
                TextField(controller: lnameCtrl, decoration: const InputDecoration(labelText: 'Last name')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (fnameCtrl.text.trim().isEmpty) return;
                            setModalState(() => saving = true);
                            try {
                              await _service.create(Patient(
                                id: '',
                                fname: fnameCtrl.text.trim(),
                                lname: lnameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              ));
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              _refresh();
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
                        : const Text('Register & generate Patient ID'),
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
      appBar: AppBar(title: const Text('Patients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPatientSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Register'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search by name or Patient ID', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Patient>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading patients…');
                }
                if (snapshot.hasError) {
                  return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
                }
                final items = snapshot.data!
                    .where((p) => _query.isEmpty || p.fullName.toLowerCase().contains(_query) || p.id.toLowerCase().contains(_query))
                    .toList();
                if (items.isEmpty) {
                  return const EmptyState(icon: Icons.people_outline_rounded, title: 'No patients found', subtitle: 'Register a new patient to get started.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: MedEaseColors.primaryLight, child: Icon(Icons.person, color: MedEaseColors.primary)),
                        title: Text(p.fullName),
                        subtitle: Text('${p.id}${p.phone != null ? ' · ${p.phone}' : ''}'),
                        trailing: p.blood != null ? Chip(label: Text(p.blood!)) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
