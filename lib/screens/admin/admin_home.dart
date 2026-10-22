import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/bed.dart';
import '../../models/bill.dart';
import '../../models/doctor.dart';
import '../../models/medicine_stock.dart';
import '../../models/patient.dart';
import '../../models/token_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/bed_service.dart';
import '../../services/billing_service.dart';
import '../../services/doctor_service.dart';
import '../../services/pharmacy_service.dart';
import '../../services/patient_service.dart';
import '../../services/api_client.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stat_card.dart';
import '../shared/profile_screen.dart';
import 'manage_doctors_screen.dart';
import 'manage_patients_screen.dart';
import 'queue_management_screen.dart';
import 'bed_management_screen.dart';
import 'analytics_screen.dart';
import 'pharmacy_screen.dart';
import 'billing_screen.dart';
import 'manual_booking_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      PatientService().getAll(),
      DoctorService().getAll(),
      AppointmentService().getAll(),
      BillingService().getAll(),
      PharmacyService().getAll(),
      BedService().getAll(),
    ]);
    return _DashboardData(
      patients: results[0] as List<Patient>,
      doctors: results[1] as List<Doctor>,
      appointments: results[2] as List<Appointment>,
      bills: results[3] as List<Bill>,
      medicines: results[4] as List<MedicineStock>,
      beds: results[5] as List<Bed>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView(message: 'Loading hospital data…');
            }
            if (snapshot.hasError) {
              return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
            }
            final d = snapshot.data!;
            final revenue = d.bills
                .where((b) => statusIs(b.status, 'paid'))
                .fold<num>(0, (sum, b) => sum + b.amount);
            final lowStock = d.medicines.where((m) => m.isLowStock).length;
            final vacantBeds = d.beds.where((b) => statusIs(b.status, 'vacant')).length;
            final activeAppointments = d.appointments.where((a) => !statusIs(a.status, 'cancelled')).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Welcome, ${user?.username ?? 'Admin'}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    StatCard(label: 'Total Patients', value: '${d.patients.length}', icon: Icons.people_alt_rounded),
                    StatCard(label: 'Total Doctors', value: '${d.doctors.length}', icon: Icons.medical_services_rounded, color: MedEaseColors.info),
                    StatCard(label: 'Appointments', value: '$activeAppointments', icon: Icons.calendar_month_rounded, color: MedEaseColors.accent),
                    StatCard(label: 'Revenue', value: '₹$revenue', icon: Icons.currency_rupee_rounded, color: MedEaseColors.success),
                    StatCard(label: 'Vacant Beds', value: '$vacantBeds/${d.beds.length}', icon: Icons.bed_rounded, color: MedEaseColors.doctorRole),
                    StatCard(label: 'Low Stock', value: '$lowStock', icon: Icons.inventory_2_rounded, color: MedEaseColors.danger),
                    StatCard(label: 'Total Bills', value: '${d.bills.length}', icon: Icons.receipt_long_rounded),
                    StatCard(
                      label: 'Active Doctors',
                      value: '${d.doctors.where((x) => statusIs(x.status, 'active')).length}',
                      icon: Icons.verified_rounded,
                      color: MedEaseColors.adminRole,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Manage', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _MenuTile(icon: Icons.add_card_rounded, label: 'Book Appointment', onTap: () => _go(context, ManualBookingScreen(doctors: d.doctors, patients: d.patients))),
                    _MenuTile(icon: Icons.medical_services_outlined, label: 'Doctors', onTap: () => _go(context, const ManageDoctorsScreen())),
                    _MenuTile(icon: Icons.people_outline_rounded, label: 'Patients', onTap: () => _go(context, const ManagePatientsScreen())),
                    _MenuTile(icon: Icons.queue_outlined, label: 'Queue & Tokens', onTap: () => _go(context, const QueueManagementScreen())),
                    _MenuTile(icon: Icons.bed_outlined, label: 'Bed Management', onTap: () => _go(context, const BedManagementScreen())),
                    _MenuTile(icon: Icons.bar_chart_rounded, label: 'Analytics', onTap: () => _go(context, const AnalyticsScreen())),
                    _MenuTile(icon: Icons.medication_outlined, label: 'Pharmacy', onTap: () => _go(context, const PharmacyScreen())),
                    _MenuTile(icon: Icons.receipt_long_outlined, label: 'Billing', onTap: () => _go(context, const BillingScreen())),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _refresh());
  }
}

class _DashboardData {
  final List<Patient> patients;
  final List<Doctor> doctors;
  final List<Appointment> appointments;
  final List<Bill> bills;
  final List<MedicineStock> medicines;
  final List<Bed> beds;
  _DashboardData({
    required this.patients,
    required this.doctors,
    required this.appointments,
    required this.bills,
    required this.medicines,
    required this.beds,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}