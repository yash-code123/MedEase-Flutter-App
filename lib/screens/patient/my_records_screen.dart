import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/bill.dart';
import '../../models/lab_order.dart';
import '../../models/prescription.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/billing_service.dart';
import '../../services/lab_service.dart';
import '../../services/prescription_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

/// My Records — Appointments / Bills / Prescriptions / Lab Results / Timeline
/// tabs, mirroring the patient portal on the web app.
class MyRecordsScreen extends StatefulWidget {
  final int initialTab;
  const MyRecordsScreen({super.key, this.initialTab = 0});

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  final _appointmentService = AppointmentService();
  final _billingService = BillingService();
  final _prescriptionService = PrescriptionService();
  final _labService = LabService();

  late Future<_RecordsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RecordsData> _load() async {
    final refId = context.read<AuthProvider>().user?.refId ?? '';
    final results = await Future.wait([
      _appointmentService.getAll(),
      _billingService.getAll(),
      _prescriptionService.getAll(),
      _labService.getAll(),
    ]);
    return _RecordsData(
      appointments: (results[0] as List<Appointment>).where((a) => a.patientId == refId).toList(),
      bills: (results[1] as List<Bill>).where((b) => b.patientId == refId).toList(),
      prescriptions: (results[2] as List<Prescription>).where((p) => p.patientId == refId).toList(),
      labOrders: (results[3] as List<LabOrder>).where((l) => l.patientId == refId).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Records'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: MedEaseColors.primary,
            unselectedLabelColor: MedEaseColors.inkMuted,
            indicatorColor: MedEaseColors.primary,
            tabs: [
              Tab(text: 'Appointments'),
              Tab(text: 'Bills'),
              Tab(text: 'Prescriptions'),
              Tab(text: 'Lab Results'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        body: FutureBuilder<_RecordsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading your records…');
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: describeDioError(snapshot.error!),
                onRetry: () { setState(() { _future = _load(); }); },
              );
            }
            final data = snapshot.data!;
            return TabBarView(
              children: [
                _AppointmentsTab(items: data.appointments),
                _BillsTab(items: data.bills),
                _PrescriptionsTab(items: data.prescriptions),
                _LabResultsTab(items: data.labOrders),
                _TimelineTab(data: data),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecordsData {
  final List<Appointment> appointments;
  final List<Bill> bills;
  final List<Prescription> prescriptions;
  final List<LabOrder> labOrders;
  _RecordsData({required this.appointments, required this.bills, required this.prescriptions, required this.labOrders});
}

class _AppointmentsTab extends StatelessWidget {
  final List<Appointment> items;
  const _AppointmentsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No appointments yet', subtitle: 'Book one from the Book tab.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.medical_services_outlined, color: MedEaseColors.primary),
            title: Text(a.doctorName ?? 'Doctor ${a.doctorId}'),
            subtitle: Text('${a.date} · ${a.time} · ₹${a.fee}'),
            trailing: StatusBadge(status: a.status),
          ),
        );
      },
    );
  }
}

class _BillsTab extends StatelessWidget {
  final List<Bill> items;
  const _BillsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No bills yet', subtitle: 'Bills appear here after booking or a visit.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final b = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: MedEaseColors.primary),
            title: Text('₹${b.amount} · ${b.mode.toUpperCase()}'),
            subtitle: Text(b.txnId != null ? 'TXN: ${b.txnId}' : (b.date ?? '')),
            trailing: StatusBadge(status: b.status),
          ),
        );
      },
    );
  }
}

class _PrescriptionsTab extends StatelessWidget {
  final List<Prescription> items;
  const _PrescriptionsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.medication_outlined, title: 'No prescriptions yet', subtitle: 'Your doctor\'s prescriptions will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: const Icon(Icons.medication_rounded, color: MedEaseColors.primary),
            title: Text(p.diagnosis.isEmpty ? 'Prescription ${p.id}' : p.diagnosis),
            subtitle: Text(p.date ?? ''),
            children: [
              if (p.vitals != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (p.vitals!.bp != null) Chip(label: Text('BP: ${p.vitals!.bp}')),
                      if (p.vitals!.pulse != null) Chip(label: Text('Pulse: ${p.vitals!.pulse}')),
                      if (p.vitals!.temp != null) Chip(label: Text('Temp: ${p.vitals!.temp}')),
                      if (p.vitals!.spo2 != null) Chip(label: Text('SpO₂: ${p.vitals!.spo2}')),
                      if (p.vitals!.bmi != null) Chip(label: Text('BMI: ${p.vitals!.bmi}')),
                    ],
                  ),
                ),
              ...p.medicines.map((m) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8, color: MedEaseColors.primary),
                    title: Text(m.name),
                    subtitle: Text('${m.dosage} · ${m.duration}'),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LabResultsTab extends StatelessWidget {
  final List<LabOrder> items;
  const _LabResultsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.biotech_outlined, title: 'No lab orders yet', subtitle: 'Test orders and results will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final l = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.biotech_rounded, color: MedEaseColors.primary),
            title: Text(l.test),
            subtitle: Text(l.result ?? 'Awaiting result — ${l.priority} priority'),
            trailing: StatusBadge(status: l.status),
          ),
        );
      },
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final _RecordsData data;
  const _TimelineTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[
      ...data.appointments.map((a) => _TimelineEvent('${a.date} ${a.time}', 'Appointment with ${a.doctorName ?? a.doctorId}', Icons.calendar_month_rounded)),
      ...data.bills.map((b) => _TimelineEvent(b.date ?? '', 'Bill of ₹${b.amount} — ${b.status}', Icons.receipt_long_rounded)),
      ...data.prescriptions.map((p) => _TimelineEvent(p.date ?? '', 'Prescription: ${p.diagnosis}', Icons.medication_rounded)),
      ...data.labOrders.map((l) => _TimelineEvent('', 'Lab test: ${l.test} — ${l.status}', Icons.biotech_rounded)),
    ]..sort((a, b) => b.when.compareTo(a.when));

    if (events.isEmpty) {
      return const EmptyState(icon: Icons.timeline_rounded, title: 'Nothing here yet', subtitle: 'Your activity will show up as a timeline.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: MedEaseColors.primaryLight, shape: BoxShape.circle),
                child: Icon(e.icon, size: 16, color: MedEaseColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (e.when.isNotEmpty)
                      Text(e.when, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineEvent {
  final String when;
  final String title;
  final IconData icon;
  _TimelineEvent(this.when, this.title, this.icon);
}
