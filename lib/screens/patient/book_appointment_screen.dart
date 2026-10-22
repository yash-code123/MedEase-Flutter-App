import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../models/token_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/doctor_service.dart';
import '../../services/patient_service.dart';
import '../../services/api_client.dart';
import '../../widgets/loading_view.dart';

/// Your clinic's real UPI collection ID.
const String kMedEaseUpiId = '9405010442@ybl';

class BookAppointmentScreen extends StatefulWidget {
  final bool embedded;
  const BookAppointmentScreen({super.key, this.embedded = false});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _doctorService = DoctorService();
  final _appointmentService = AppointmentService();
  final _patientService = PatientService();
  final _txnIdCtrl = TextEditingController();

  int _step = 0;
  String? _department;
  Doctor? _doctor;
  DateTime? _date;
  String? _time;
  bool _booking = false;
  Appointment? _confirmed;

  List<Doctor> _allDoctors = [];
  Patient? _me;
  bool _loadingDoctors = true;
  String? _loadError;

  static const _slots = ['09:00 AM', '10:00 AM', '11:30 AM', '02:00 PM', '03:30 PM', '05:00 PM'];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _txnIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final refId = context.read<AuthProvider>().user?.refId ?? '';
      final doctorsFuture = _doctorService.getAll();
      Patient? me;
      try {
        me = await _patientService.getById(refId);
      } catch (_) {
        me = null;
      }
      final doctors = await doctorsFuture;
      setState(() {
        _allDoctors = doctors.where((d) => statusIs(d.status, 'active')).toList();
        _me = me;
        _loadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _loadError = describeDioError(e);
        _loadingDoctors = false;
      });
    }
  }

  List<String> get _departments => _allDoctors.map((d) => d.dept).toSet().toList()..sort();

  List<Doctor> get _doctorsInDept => _allDoctors.where((d) => d.dept == _department).toList();

  Future<void> _confirmBooking() async {
    final refId = context.read<AuthProvider>().user?.refId;
    if (refId == null || _doctor == null || _date == null || _time == null) return;
    setState(() => _booking = true);
    try {
      final appointment = await _appointmentService.book(Appointment(
        id: '',
        patientId: refId,
        doctorId: _doctor!.id,
        patientName: _me?.fullName,
        doctorName: _doctor!.name,
        department: _doctor!.dept,
        date: '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
        time: _time!,
        fee: _doctor!.fee,
        type: 'New Visit',
        phone: _me?.phone,
        payMode: 'upi',
        txnId: _txnIdCtrl.text.trim().isEmpty ? null : _txnIdCtrl.text.trim(),
      ));
      setState(() {
        _confirmed = appointment;
        _step = 4;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _resetWizard() {
    setState(() {
      _step = 0;
      _department = null;
      _doctor = null;
      _date = null;
      _time = null;
      _confirmed = null;
      _txnIdCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _loadingDoctors
        ? const LoadingView(message: 'Loading doctors…')
        : _loadError != null
        ? ErrorView(
      message: _loadError!,
      onRetry: () {
        setState(() => _loadingDoctors = true);
        _loadInitial();
      },
    )
        : Column(
      children: [
        if (_step < 4) _StepIndicator(step: _step),
        Expanded(child: _buildStep()),
      ],
    );

    return Scaffold(appBar: AppBar(title: const Text('Book Appointment')), body: body);
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _DepartmentStep(
          departments: _departments,
          onSelect: (d) => setState(() {
            _department = d;
            _step = 1;
          }),
        );
      case 1:
        return _DoctorStep(
          doctors: _doctorsInDept,
          onSelect: (d) => setState(() {
            _doctor = d;
            _step = 2;
          }),
          onBack: () => setState(() => _step = 0),
        );
      case 2:
        return _SlotStep(
          date: _date,
          time: _time,
          slots: _slots,
          onDatePicked: (d) => setState(() => _date = d),
          onSlotPicked: (t) => setState(() => _time = t),
          onNext: (_date != null && _time != null) ? () => setState(() => _step = 3) : null,
          onBack: () => setState(() => _step = 1),
        );
      case 3:
        return _PaymentStep(
          doctor: _doctor!,
          date: _date!,
          time: _time!,
          booking: _booking,
          txnIdCtrl: _txnIdCtrl,
          onPay: _confirmBooking,
          onBack: () => setState(() => _step = 2),
        );
      default:
        return _ConfirmationStep(appointment: _confirmed!, onDone: _resetWizard);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Department', 'Doctor', 'Slot', 'Payment'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i <= step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: active ? MedEaseColors.primary : MedEaseColors.border,
                  child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: active ? Colors.white : MedEaseColors.inkMuted)),
                ),
                if (i != labels.length - 1)
                  Expanded(child: Container(height: 2, color: i < step ? MedEaseColors.primary : MedEaseColors.border)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DepartmentStep extends StatelessWidget {
  final List<String> departments;
  final void Function(String) onSelect;
  const _DepartmentStep({required this.departments, required this.onSelect});

  static const _icons = {
    'Cardiology': Icons.favorite_rounded,
    'Neurology': Icons.psychology_rounded,
    'Pediatrics': Icons.child_care_rounded,
    'Orthopedics': Icons.accessibility_new_rounded,
    'Gynecology': Icons.pregnant_woman_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (departments.isEmpty) {
      return const _LocalEmptyState(icon: Icons.local_hospital_outlined, title: 'No departments available', subtitle: 'Please check back later.');
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: departments.map((dept) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(dept),
            child: Container(
              decoration: BoxDecoration(color: MedEaseColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: MedEaseColors.border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icons[dept] ?? Icons.medical_services_rounded, color: MedEaseColors.primary, size: 28),
                  const SizedBox(height: 10),
                  Text(dept, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DoctorStep extends StatelessWidget {
  final List<Doctor> doctors;
  final void Function(Doctor) onSelect;
  final VoidCallback onBack;
  const _DoctorStep({required this.doctors, required this.onSelect, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Department')),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: doctors.length,
            itemBuilder: (context, i) {
              final d = doctors[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => onSelect(d),
                  leading: const CircleAvatar(backgroundColor: MedEaseColors.primaryLight, child: Icon(Icons.person, color: MedEaseColors.primary)),
                  title: Text(d.name),
                  subtitle: Text(d.qualification ?? d.dept),
                  trailing: Text('₹${d.fee}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SlotStep extends StatelessWidget {
  final DateTime? date;
  final String? time;
  final List<String> slots;
  final void Function(DateTime) onDatePicked;
  final void Function(String) onSlotPicked;
  final VoidCallback? onNext;
  final VoidCallback onBack;

  const _SlotStep({required this.date, required this.time, required this.slots, required this.onDatePicked, required this.onSlotPicked, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Doctor')),
          const SizedBox(height: 8),
          Text('Choose a date', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(date == null ? 'Pick a date' : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
              if (picked != null) onDatePicked(picked);
            },
          ),
          const SizedBox(height: 20),
          Text('Choose a slot', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((s) {
              final selected = s == time;
              return ChoiceChip(
                label: Text(s),
                selected: selected,
                onSelected: (_) => onSlotPicked(s),
                selectedColor: MedEaseColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : MedEaseColors.ink),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onNext, child: const Text('Continue to payment'))),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;
  final String time;
  final bool booking;
  final TextEditingController txnIdCtrl;
  final VoidCallback onPay;
  final VoidCallback onBack;

  const _PaymentStep({
    required this.doctor,
    required this.date,
    required this.time,
    required this.booking,
    required this.txnIdCtrl,
    required this.onPay,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final upiString = 'upi://pay?pa=$kMedEaseUpiId&pn=MedEase&am=${doctor.fee}&cu=INR&tn=Consultation%20${doctor.id}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Slot')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summaryRow('Doctor', doctor.name),
                  _summaryRow('Department', doctor.dept),
                  _summaryRow('Date', '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                  _summaryRow('Time', time),
                  const Divider(height: 24),
                  _summaryRow('Consultation fee', '₹${doctor.fee}', bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Scan to pay with any UPI app', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Pay to: $kMedEaseUpiId', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: MedEaseColors.border)),
              child: QrImageView(data: upiString, size: 180),
            ),
          ),
          const SizedBox(height: 24),
          Text('After paying, enter the transaction ID', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('You\'ll find this in your UPI app\'s payment confirmation screen.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(
            controller: txnIdCtrl,
            decoration: const InputDecoration(hintText: 'e.g. 423187654321', prefixIcon: Icon(Icons.receipt_long_rounded)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: booking ? null : onPay,
              child: booking
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("I've completed the payment"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: MedEaseColors.inkMuted, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onDone;
  const _ConfirmationStep({required this.appointment, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: MedEaseColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Appointment confirmed!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Your queue token has been generated automatically. You can view it from Home.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onDone, child: const Text('Book another'))),
          ],
        ),
      ),
    );
  }
}

class _LocalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _LocalEmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: MedEaseColors.inkMuted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}