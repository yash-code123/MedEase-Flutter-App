import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../services/appointment_service.dart';
import '../../services/api_client.dart';

/// Front-desk / admin booking. Books an appointment on behalf of ANY
/// patient. This is also how a queue token gets created manually —
/// the backend only creates tokens as a side effect of booking an
/// appointment, there's no separate "create token" endpoint.
class ManualBookingScreen extends StatefulWidget {
  final List<Doctor> doctors;
  final List<Patient> patients;
  const ManualBookingScreen({super.key, required this.doctors, required this.patients});

  @override
  State<ManualBookingScreen> createState() => _ManualBookingScreenState();
}

class _ManualBookingScreenState extends State<ManualBookingScreen> {
  final _service = AppointmentService();
  Patient? _patient;
  Doctor? _doctor;
  DateTime _date = DateTime.now();
  final _timeCtrl = TextEditingController(text: '10:00 AM');
  String _type = 'New Visit';
  String _payMode = 'cash';
  bool _saving = false;
  String _patientQuery = '';

  List<Patient> get _filteredPatients => widget.patients
      .where((p) =>
  _patientQuery.isEmpty ||
      p.fullName.toLowerCase().contains(_patientQuery.toLowerCase()) ||
      p.id.toLowerCase().contains(_patientQuery.toLowerCase()))
      .toList();

  Future<void> _submit() async {
    if (_patient == null || _doctor == null) return;
    setState(() => _saving = true);
    try {
      await _service.book(Appointment(
        id: '',
        patientId: _patient!.id,
        doctorId: _doctor!.id,
        patientName: _patient!.fullName,
        doctorName: _doctor!.name,
        department: _doctor!.dept,
        date: '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        time: _timeCtrl.text.trim(),
        fee: _doctor!.fee,
        type: _type,
        phone: _patient!.phone,
        payMode: _payMode,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked and queue token generated.'), backgroundColor: MedEaseColors.success),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('This books an appointment and generates a queue token in one step.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          Text('Patient', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(hintText: 'Search by name or Patient ID', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _patientQuery = v),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(border: Border.all(color: MedEaseColors.border), borderRadius: BorderRadius.circular(12)),
            child: _filteredPatients.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('No matching patients'))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredPatients.length,
              itemBuilder: (context, i) {
                final p = _filteredPatients[i];
                final selected = _patient?.id == p.id;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: MedEaseColors.primaryLight,
                  title: Text(p.fullName),
                  subtitle: Text(p.id),
                  onTap: () => setState(() => _patient = p),
                );
              },
            ),
          ),
          if (_patient != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text('Selected: ${_patient!.fullName} (${_patient!.id})'),
              onDeleted: () => setState(() => _patient = null),
            ),
          ],
          const SizedBox(height: 24),
          Text('Doctor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<Doctor>(
            value: _doctor,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Select a doctor'),
            items: widget.doctors
                .map((d) => DropdownMenuItem(value: d, child: Text('${d.name} · ${d.dept} · ₹${d.fee}')))
                .toList(),
            onChanged: (d) => setState(() => _doctor = d),
          ),
          const SizedBox(height: 24),
          Text('Date & time', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(controller: _timeCtrl, decoration: const InputDecoration(hintText: 'e.g. 10:00 AM')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Type', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['New Visit', 'Follow-Up', 'Emergency'].map((t) {
              final selected = t == _type;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: t == 'Emergency' ? MedEaseColors.danger : MedEaseColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : MedEaseColors.ink),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Payment mode', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['cash', 'upi', 'card'].map((m) {
              final selected = m == _payMode;
              return ChoiceChip(
                label: Text(m.toUpperCase()),
                selected: selected,
                onSelected: (_) => setState(() => _payMode = m),
                selectedColor: MedEaseColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : MedEaseColors.ink),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_patient != null && _doctor != null && !_saving) ? _submit : null,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Book & generate token'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}