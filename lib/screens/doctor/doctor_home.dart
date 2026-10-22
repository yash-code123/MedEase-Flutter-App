import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/doctor.dart';
import '../../models/token_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/doctor_service.dart';
import '../../services/token_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stat_card.dart';
import 'consultation_screen.dart';

/// Doctor's personal queue. Your backend stores a token's doctor as a
/// plain `doctor_name` string (no doctor_id link), so we resolve the
/// logged-in doctor's own name from their Doctor ID first, then match
/// tokens by that name.
class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  final _tokenService = TokenService();
  final _doctorService = DoctorService();
  late Future<_DoctorQueueData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DoctorQueueData> _load() async {
    final refId = context.read<AuthProvider>().user?.refId ?? '';
    final results = await Future.wait([_tokenService.getAll(), _doctorService.getAll()]);
    final tokens = results[0] as List<QueueToken>;
    final doctors = results[1] as List<Doctor>;

    final me = doctors.where((d) => d.id == refId).toList();
    final myProfile = me.isNotEmpty ? me.first : null;
    final myName = myProfile?.name.replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim().toLowerCase();

    final myTokens = tokens.where((t) {
      if (statusIs(t.status, 'done')) return false;
      if (myName == null || myName.isEmpty) return false;
      final tokenDoctor = (t.doctorName ?? '').replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim().toLowerCase();
      return tokenDoctor == myName;
    }).toList()
      ..sort((a, b) {
        if (statusIs(a.priority, 'emergency') && !statusIs(b.priority, 'emergency')) return -1;
        if (!statusIs(a.priority, 'emergency') && statusIs(b.priority, 'emergency')) return 1;
        return a.id.compareTo(b.id);
      });

    final completedToday = tokens.where((t) {
      if (myName == null || myName.isEmpty) return false;
      final tokenDoctor = (t.doctorName ?? '').replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim().toLowerCase();
      return tokenDoctor == myName && statusIs(t.status, 'done');
    }).length;

    return _DoctorQueueData(myProfile: myProfile, waiting: myTokens, completedToday: completedToday);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _callPatient(QueueToken token) async {
    await _tokenService.updateStatus(token.id, 'In Progress');
    if (!mounted) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConsultationScreen(token: token)),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${user?.username ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => context.read<AuthProvider>().logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DoctorQueueData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading your queue…');
            }
            if (snapshot.hasError) {
              return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (data.myProfile != null) _ProfileHeader(doctor: data.myProfile!),
                if (data.myProfile == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: MedEaseColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Could not find your doctor profile — your login may not be linked to a Doctor record. Contact the admin.',
                      style: TextStyle(fontSize: 12, color: MedEaseColors.danger),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(child: StatCard(label: 'Waiting now', value: '${data.waiting.length}', icon: Icons.hourglass_top_rounded, color: MedEaseColors.accent)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Completed today', value: '${data.completedToday}', icon: Icons.check_circle_rounded, color: MedEaseColors.success)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Your queue', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (data.waiting.isEmpty)
                  const EmptyState(
                    icon: Icons.self_improvement_rounded,
                    title: 'No patients waiting',
                    subtitle: 'Your queue is clear right now.',
                  )
                else
                  ...data.waiting.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    final isNext = i == 0;
                    final isEmergency = statusIs(t.priority, 'emergency');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isEmergency
                          ? MedEaseColors.danger.withValues(alpha: 0.06)
                          : (isNext ? MedEaseColors.primaryLight : MedEaseColors.surface),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEmergency ? MedEaseColors.danger : (isNext ? MedEaseColors.primary : MedEaseColors.background),
                          child: Text(t.id.replaceAll('T-', ''), style: TextStyle(fontSize: 11, color: (isNext || isEmergency) ? Colors.white : MedEaseColors.ink)),
                        ),
                        title: Text(t.patientName ?? 'Patient ${t.patientId}'),
                        subtitle: Text('Token ${t.id} · ${t.status}${isEmergency ? ' · Emergency' : ''}'),
                        trailing: FilledButton(
                          style: isEmergency ? FilledButton.styleFrom(backgroundColor: MedEaseColors.danger) : null,
                          onPressed: () => _callPatient(t),
                          child: Text(isNext ? 'Call next' : 'Call'),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DoctorQueueData {
  final Doctor? myProfile;
  final List<QueueToken> waiting;
  final int completedToday;
  _DoctorQueueData({required this.myProfile, required this.waiting, required this.completedToday});
}

class _ProfileHeader extends StatelessWidget {
  final Doctor doctor;
  const _ProfileHeader({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [MedEaseColors.doctorRole, Color(0xFF2E5F97)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              doctor.name.replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim().isNotEmpty
                  ? doctor.name.replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').trim()[0].toUpperCase()
                  : 'D',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${doctor.dept}${doctor.qualification != null ? ' · ${doctor.qualification}' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Fee: ₹${doctor.fee}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}