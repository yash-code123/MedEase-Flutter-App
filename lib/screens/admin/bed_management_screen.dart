import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/bed.dart';
import '../../models/token_model.dart';
import '../../services/bed_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

class BedManagementScreen extends StatefulWidget {
  const BedManagementScreen({super.key});

  @override
  State<BedManagementScreen> createState() => _BedManagementScreenState();
}

class _BedManagementScreenState extends State<BedManagementScreen> {
  final _bedService = BedService();
  late Future<List<Bed>> _future;

  @override
  void initState() {
    super.initState();
    _future = _bedService.getAll();
  }

  void _refresh() {
    final next = _bedService.getAll();
    setState(() {
      _future = next;
    });
  }

  Future<void> _openEditDialog(Bed bed) async {
    String status = ['available', 'occupied', 'maintenance'].firstWhere(
          (s) => statusIs(bed.status, s),
      orElse: () => 'available',
    );
    final patientCtrl = TextEditingController(text: bed.patientId ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Manage Bed ${bed.id} — ${bed.ward}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        status = v ?? 'available';
                        if (status != 'occupied') patientCtrl.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Patient name (if occupied)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: patientCtrl,
                    enabled: status == 'occupied',
                    decoration: const InputDecoration(hintText: 'e.g. Rajesh Kumar or P-1001'),
                  ),
                  const SizedBox(height: 16),
                  Text('Ward: ${bed.ward}', style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                  setDialogState(() {
                    saving = true;
                  });
                  try {
                    await _bedService.updateBed(
                      bed.id,
                      status,
                      status == 'occupied' && patientCtrl.text.trim().isNotEmpty ? patientCtrl.text.trim() : null,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    _refresh();
                  } catch (e) {
                    setDialogState(() {
                      saving = false;
                    });
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
                      );
                    }
                  }
                },
                child: saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bed Management')),
      body: FutureBuilder<List<Bed>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading wards…');
          }
          if (snapshot.hasError) {
            return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
          }
          final beds = snapshot.data!;
          if (beds.isEmpty) {
            return const EmptyState(icon: Icons.bed_outlined, title: 'No beds configured', subtitle: 'Ward data will appear here once set up.');
          }
          final byWard = <String, List<Bed>>{};
          for (final b in beds) {
            byWard.putIfAbsent(b.ward, () => []).add(b);
          }
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: byWard.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.95,
                        children: entry.value.map((bed) {
                          final occupied = statusIs(bed.status, 'occupied');
                          final maintenance = statusIs(bed.status, 'maintenance');
                          final color = maintenance ? MedEaseColors.warning : (occupied ? MedEaseColors.danger : MedEaseColors.success);
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _openEditDialog(bed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bed_rounded, size: 16, color: color),
                                  const SizedBox(height: 2),
                                  Text(bed.id, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                  if (bed.patientId != null && bed.patientId!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        bed.patientId!,
                                        style: const TextStyle(fontSize: 8),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}