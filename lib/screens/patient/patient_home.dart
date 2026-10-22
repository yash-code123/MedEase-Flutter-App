import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/token_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/token_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/section_header.dart';
import 'book_appointment_screen.dart';
import 'my_records_screen.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _appointmentService = AppointmentService();
  final _tokenService = TokenService();

  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final refId = context.read<AuthProvider>().user?.refId ?? '';
    final results = await Future.wait([_appointmentService.getAll(), _tokenService.getAll()]);
    final appointments = (results[0] as List<Appointment>).where((a) => a.patientId == refId).toList()
      ..sort((a, b) => '${b.date} ${b.time}'.compareTo('${a.date} ${a.time}'));
    final tokens = (results[1] as List<QueueToken>).where((t) => t.patientId == refId).toList();
    return _HomeData(appointments: appointments, tokens: tokens);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  void _openBook() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookAppointmentScreen())).then((_) => _refresh());
  }

  void _openRecords({int tab = 0}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyRecordsScreen(initialTab: tab))).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.username ?? 'there'} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading your dashboard…');
            }
            if (snapshot.hasError) {
              return ErrorView(message: 'Could not load your data.\n${snapshot.error}', onRetry: _refresh);
            }
            final data = snapshot.data!;
            final upcoming = data.appointments.where((a) => !statusIs(a.status, 'cancelled')).take(3).toList();
            final activeToken = data.tokens.where((t) => !statusIs(t.status, 'done')).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeToken.isNotEmpty) _TokenBanner(token: activeToken.first),
                const SectionHeader(title: 'Upcoming appointments'),
                if (upcoming.isEmpty)
                  const _EmptyRow(text: 'No upcoming appointments — tap Book to schedule one.')
                else
                  ...upcoming.map((a) => _AppointmentTile(appointment: a)),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Quick actions'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _QuickAction(icon: Icons.calendar_month_rounded, label: 'Book Appointment', onTap: _openBook),
                    _QuickAction(icon: Icons.receipt_long_rounded, label: 'My Bills', onTap: () => _openRecords(tab: 1)),
                    _QuickAction(icon: Icons.medication_rounded, label: 'Prescriptions', onTap: () => _openRecords(tab: 2)),
                    _QuickAction(icon: Icons.biotech_rounded, label: 'Lab Results', onTap: () => _openRecords(tab: 3)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  final List<Appointment> appointments;
  final List<QueueToken> tokens;
  _HomeData({required this.appointments, required this.tokens});
}

class _TokenBanner extends StatelessWidget {
  final QueueToken token;
  const _TokenBanner({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: MedEaseColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your queue token: ${token.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Status: ${token.status}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MedEaseColors.primaryLight,
          child: const Icon(Icons.medical_services_outlined, color: MedEaseColors.primary, size: 20),
        ),
        title: Text(appointment.doctorName ?? 'Doctor ${appointment.doctorId}'),
        subtitle: Text('${appointment.date} · ${appointment.time}'),
        trailing: StatusBadge(status: appointment.status),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MedEaseColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MedEaseColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MedEaseColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: MedEaseColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedEaseColors.border)),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}