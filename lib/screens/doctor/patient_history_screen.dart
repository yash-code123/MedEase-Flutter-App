import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/prescription.dart';
import '../../providers/auth_provider.dart';
import '../../services/prescription_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

/// Doctor's view of past prescriptions they've written — quick reference
/// for a patient's medical history, mirrors the web doctor console.
class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final _service = PrescriptionService();
  late Future<List<Prescription>> _future;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Prescription>> _load() async {
    final refId = context.read<AuthProvider>().user?.refId ?? '';
    final all = await _service.getAll();
    return all.where((p) => p.doctorId == refId).toList()
      ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by patient ID or diagnosis',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Prescription>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading history…');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: describeDioError(snapshot.error!),
                    onRetry: () { setState(() { _future = _load(); }); },
                  );
                }
                final items = snapshot.data!
                    .where((p) => _query.isEmpty || p.patientId.toLowerCase().contains(_query) || p.diagnosis.toLowerCase().contains(_query))
                    .toList();
                if (items.isEmpty) {
                  return const EmptyState(icon: Icons.folder_off_outlined, title: 'No records found', subtitle: 'Consultations you complete will show up here.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: MedEaseColors.primaryLight, child: Icon(Icons.person, color: MedEaseColors.primary, size: 18)),
                        title: Text('Patient ${p.patientId}'),
                        subtitle: Text(p.diagnosis.isEmpty ? '—' : p.diagnosis),
                        children: p.medicines
                            .map((m) => ListTile(
                                  dense: true,
                                  title: Text(m.name),
                                  subtitle: Text('${m.dosage} · ${m.duration}'),
                                ))
                            .toList(),
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
