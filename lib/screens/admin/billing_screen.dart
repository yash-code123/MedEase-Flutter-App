import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/bill.dart';
import '../../models/token_model.dart';
import '../../services/billing_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _service = BillingService();
  late Future<List<Bill>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _reload() {
    final next = _service.getAll();
    setState(() {
      _future = next;
    });
  }

  Future<void> _submitManualBill(String patientId, num amount, String mode, void Function(bool) setSaving, void Function() closeSheet) async {
    setSaving(true);
    try {
      await _service.create(patientId: patientId, amount: amount, mode: mode);
      closeSheet();
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDioError(e)), backgroundColor: MedEaseColors.danger),
      );
    } finally {
      setSaving(false);
    }
  }

  Future<void> _openManualBillSheet() async {
    final patientIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String mode = 'cash';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add manual bill', style: Theme.of(ctx).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    TextField(controller: patientIdCtrl, decoration: const InputDecoration(labelText: 'Patient ID (e.g. P-1001)')),
                    const SizedBox(height: 12),
                    TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['cash', 'upi', 'card'].map((m) {
                        final selected = m == mode;
                        return ChoiceChip(
                          label: Text(m.toUpperCase()),
                          selected: selected,
                          onSelected: (_) {
                            setModalState(() {
                              mode = m;
                            });
                          },
                          selectedColor: MedEaseColors.primary,
                          labelStyle: TextStyle(color: selected ? Colors.white : MedEaseColors.ink),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                          final amount = num.tryParse(amountCtrl.text.trim());
                          final patientId = patientIdCtrl.text.trim();
                          if (patientId.isEmpty || amount == null) return;
                          _submitManualBill(
                            patientId,
                            amount,
                            mode,
                                (v) {
                              setModalState(() {
                                saving = v;
                              });
                            },
                                () {
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                          );
                        },
                        child: saving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Add bill'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openManualBillSheet();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Manual bill'),
      ),
      body: FutureBuilder<List<Bill>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading bills…');
          }
          if (snapshot.hasError) {
            return ErrorView(message: describeDioError(snapshot.error!), onRetry: _reload);
          }
          final bills = snapshot.data!;
          if (bills.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No bills yet', subtitle: 'Bills generated across the hospital appear here.');
          }
          final totalRevenue = bills.where((b) => statusIs(b.status, 'paid')).fold<num>(0, (s, b) => s + b.amount);
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: MedEaseColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total revenue', style: TextStyle(color: Colors.white70)),
                    Text('₹$totalRevenue', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: bills.length,
                  itemBuilder: (context, i) {
                    final b = bills[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded, color: MedEaseColors.primary),
                        title: Text('₹${b.amount} · Patient ${b.patientId}'),
                        subtitle: Text('${b.mode.toUpperCase()}${b.txnId != null ? ' · ${b.txnId}' : ''}'),
                        trailing: StatusBadge(status: b.status),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}