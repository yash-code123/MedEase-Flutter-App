import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/prescription.dart';
import '../../models/lab_order.dart';
import '../../models/token_model.dart';
import '../../services/prescription_service.dart';
import '../../services/lab_service.dart';
import '../../services/token_service.dart';
import '../../services/api_client.dart';

/// Full consultation flow: record vitals (auto-calculates BMI), write a
/// multi-medicine prescription, optionally order a lab test, then
/// mark the patient's token as done — mirrors the web doctor console.
class ConsultationScreen extends StatefulWidget {
  final QueueToken token;
  const ConsultationScreen({super.key, required this.token});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _Med {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final duration = TextEditingController();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _prescriptionService = PrescriptionService();
  final _labService = LabService();
  final _tokenService = TokenService();

  final _bp = TextEditingController();
  final _pulse = TextEditingController();
  final _temp = TextEditingController();
  final _spo2 = TextEditingController();
  final _heightCm = TextEditingController();
  final _weightKg = TextEditingController();
  final _diagnosis = TextEditingController();
  final _labTest = TextEditingController();
  String _labPriority = 'routine';

  final List<_Med> _medicines = [_Med()];
  bool _saving = false;

  String get _bmi {
    final h = double.tryParse(_heightCm.text);
    final w = double.tryParse(_weightKg.text);
    if (h == null || w == null || h <= 0) return '';
    final m = h / 100;
    return (w / (m * m)).toStringAsFixed(1);
  }

  Future<void> _finishConsultation() async {
    setState(() => _saving = true);
    try {
      await _prescriptionService.create(Prescription(
        id: '',
        patientId: widget.token.patientId,
        diagnosis: _diagnosis.text.trim(),
        medicines: _medicines
            .where((m) => m.name.text.trim().isNotEmpty)
            .map((m) => Medicine(name: m.name.text.trim(), dosage: m.dosage.text.trim(), duration: m.duration.text.trim()))
            .toList(),
        vitals: Vitals(
          bp: _bp.text.trim().isEmpty ? null : _bp.text.trim(),
          pulse: _pulse.text.trim().isEmpty ? null : _pulse.text.trim(),
          temp: _temp.text.trim().isEmpty ? null : _temp.text.trim(),
          spo2: _spo2.text.trim().isEmpty ? null : _spo2.text.trim(),
          bmi: _bmi.isEmpty ? null : _bmi,
        ),
      ));

      if (_labTest.text.trim().isNotEmpty) {
        await _labService.order(LabOrder(
          id: '',
          patientId: widget.token.patientId,
          test: _labTest.text.trim(),
          priority: _labPriority,
        ));
      }

      await _tokenService.updateStatus(widget.token.id, 'Done');

      if (!mounted) return;
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
      appBar: AppBar(title: Text('Consultation · ${widget.token.patientName ?? widget.token.patientId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vitals', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _bp, decoration: const InputDecoration(labelText: 'BP (e.g. 120/80)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pulse, decoration: const InputDecoration(labelText: 'Pulse (bpm)'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _temp, decoration: const InputDecoration(labelText: 'Temp (°F)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _spo2, decoration: const InputDecoration(labelText: 'SpO₂ (%)'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightCm,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _weightKg,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_bmi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Chip(label: Text('BMI (auto): $_bmi'), backgroundColor: MedEaseColors.primaryLight),
            ],
            const SizedBox(height: 24),
            Text('Diagnosis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _diagnosis,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. Viral fever with mild dehydration'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medicines', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: () => setState(() => _medicines.add(_Med())),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add row'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._medicines.asMap().entries.map((entry) {
              final i = entry.key;
              final med = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(controller: med.name, decoration: const InputDecoration(labelText: 'Medicine name')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: med.dosage, decoration: const InputDecoration(labelText: 'Dosage (e.g. 1-0-1)'))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: med.duration, decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)'))),
                          if (_medicines.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _medicines.removeAt(i)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text('Order a lab test (optional)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: _labTest, decoration: const InputDecoration(hintText: 'e.g. Complete Blood Count')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['routine', 'urgent'].map((p) {
                final selected = p == _labPriority;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() => _labPriority = p),
                  selectedColor: MedEaseColors.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : MedEaseColors.ink),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _finishConsultation,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Finish consultation'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
