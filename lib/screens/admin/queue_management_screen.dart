import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../models/token_model.dart';
import '../../services/doctor_service.dart';
import '../../services/patient_service.dart';
import '../../services/token_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import 'manual_booking_screen.dart';

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  final _tokenService = TokenService();
  late Future<_QueueData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_QueueData> _load() async {
    final results = await Future.wait([
      TokenService().getAll(),
      DoctorService().getAll(),
      PatientService().getAll(),
    ]);
    return _QueueData(
      tokens: results[0] as List<QueueToken>,
      doctors: results[1] as List<Doctor>,
      patients: results[2] as List<Patient>,
    );
  }

  void _refresh() { setState(() { _future = _load(); }); }

  Future<void> _editStatus(QueueToken t) async {
    final newStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Update status', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final s in ['Waiting', 'In Progress', 'Done'])
              ListTile(title: Text(s), onTap: () => Navigator.of(ctx).pop(s)),
          ],
        ),
      ),
    );
    if (newStatus == null) return;
    try {
      await _tokenService.updateStatus(t.id, newStatus);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queue & Tokens')),
      floatingActionButton: FutureBuilder<_QueueData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.add_rounded),
            label: const Text('New token'),
            onPressed: () async {
              final result = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ManualBookingScreen(doctors: snapshot.data!.doctors, patients: snapshot.data!.patients),
              ));
              if (result == true) _refresh();
            },
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await _future;
        },
        child: FutureBuilder<_QueueData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading queue…');
            }
            if (snapshot.hasError) {
              return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
            }
            final tokens = snapshot.data!.tokens
              ..sort((a, b) {
                // Emergency tokens float to the top
                if (statusIs(a.priority, 'emergency') && !statusIs(b.priority, 'emergency')) return -1;
                if (!statusIs(a.priority, 'emergency') && statusIs(b.priority, 'emergency')) return 1;
                return a.id.compareTo(b.id);
              });
            if (tokens.isEmpty) {
              return const EmptyState(icon: Icons.queue_outlined, title: 'Queue is empty', subtitle: 'Tap "New token" to book a walk-in patient.');
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: tokens.length,
              itemBuilder: (context, i) {
                final t = tokens[i];
                final isEmergency = statusIs(t.priority, 'emergency');
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isEmergency ? MedEaseColors.danger.withValues(alpha: 0.06) : null,
                  child: ListTile(
                    onTap: () => _editStatus(t),
                    leading: CircleAvatar(
                      backgroundColor: isEmergency ? MedEaseColors.danger.withValues(alpha: 0.15) : MedEaseColors.primaryLight,
                      child: Text(t.id.replaceAll('T-', ''), style: TextStyle(fontSize: 11, color: isEmergency ? MedEaseColors.danger : MedEaseColors.primary)),
                    ),
                    title: Text(t.patientName ?? 'Patient ${t.patientId}'),
                    subtitle: Text('Dr. ${t.doctorName ?? '—'}${isEmergency ? ' · Emergency' : ''}'),
                    trailing: StatusBadge(status: t.status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _QueueData {
  final List<QueueToken> tokens;
  final List<Doctor> doctors;
  final List<Patient> patients;
  _QueueData({required this.tokens, required this.doctors, required this.patients});
}