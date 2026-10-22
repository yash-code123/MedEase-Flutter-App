import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/medicine_stock.dart';
import '../../services/pharmacy_service.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

/// Pharmacy inventory with low-stock alerts & expiry tracking.
class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _service = PharmacyService();
  late Future<List<MedicineStock>> _future;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _refresh() => setState(() => _future = _service.getAll());

  Future<void> _adjustStock(MedicineStock m, int delta) async {
    final newQty = (m.quantity + delta).clamp(0, 999999);
    try {
      await _service.updateStock(m.id, newQty);
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
      appBar: AppBar(
        title: const Text('Pharmacy'),
        actions: [
          IconButton(
            icon: Icon(_lowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Show low stock only',
            onPressed: () => setState(() => _lowStockOnly = !_lowStockOnly),
          ),
        ],
      ),
      body: FutureBuilder<List<MedicineStock>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading inventory…');
          }
          if (snapshot.hasError) {
            return ErrorView(message: describeDioError(snapshot.error!), onRetry: _refresh);
          }
          var items = snapshot.data!;
          if (_lowStockOnly) items = items.where((m) => m.isLowStock).toList();
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.medication_outlined, title: 'No medicines found', subtitle: 'Inventory items will appear here.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: m.isLowStock ? MedEaseColors.danger.withValues(alpha: 0.05) : null,
                child: ListTile(
                  leading: Icon(Icons.medication_rounded, color: m.isLowStock ? MedEaseColors.danger : MedEaseColors.primary),
                  title: Text(m.name),
                  subtitle: Text('${m.category}${m.expiry != null ? ' · exp ${m.expiry}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => _adjustStock(m, -1)),
                      Text('${m.quantity}', style: TextStyle(fontWeight: FontWeight.w700, color: m.isLowStock ? MedEaseColors.danger : MedEaseColors.ink)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => _adjustStock(m, 1)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
