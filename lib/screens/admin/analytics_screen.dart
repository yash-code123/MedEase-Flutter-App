import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../models/appointment.dart';
import '../../models/bill.dart';
import '../../models/doctor.dart';
import '../../models/token_model.dart';
import '../../services/appointment_service.dart';
import '../../services/billing_service.dart';
import '../../services/doctor_service.dart';
import '../../services/api_client.dart';
import '../../widgets/loading_view.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AnalyticsData> _load() async {
    final results = await Future.wait([
      BillingService().getAll(),
      DoctorService().getAll(),
      AppointmentService().getAll(),
    ]);
    return _AnalyticsData(
      bills: results[0] as List<Bill>,
      doctors: results[1] as List<Doctor>,
      appointments: results[2] as List<Appointment>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<_AnalyticsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Crunching numbers…');
          }
          if (snapshot.hasError) {
            return ErrorView(message: describeDioError(snapshot.error!), onRetry: () { setState(() { _future = _load(); }); });
          }
          final data = snapshot.data!;
          final paidBills = data.bills.where((b) => statusIs(b.status, 'paid')).toList();
          final totalRevenue = paidBills.fold<num>(0, (s, b) => s + b.amount);

          final revenueByDate = <String, num>{};
          for (final b in paidBills) {
            final key = (b.date ?? '').split('T').first;
            if (key.isEmpty) continue;
            revenueByDate[key] = (revenueByDate[key] ?? 0) + b.amount;
          }
          final sortedDates = revenueByDate.keys.toList()..sort();
          final last7 = sortedDates.length > 7 ? sortedDates.sublist(sortedDates.length - 7) : sortedDates;

          final apptsByDept = <String, int>{};
          for (final a in data.appointments) {
            final dept = a.department ?? 'Other';
            apptsByDept[dept] = (apptsByDept[dept] ?? 0) + 1;
          }

          final apptsByStatus = <String, int>{};
          for (final a in data.appointments) {
            final s = a.status.isEmpty ? 'Unknown' : a.status;
            apptsByStatus[s] = (apptsByStatus[s] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MedEaseColors.primary, MedEaseColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total revenue (paid bills)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('₹$totalRevenue', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${paidBills.length} paid bills · ${data.appointments.length} appointments total',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Revenue trend', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: last7.isEmpty
                    ? const Center(child: Text('No paid bills yet'))
                    : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= last7.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(last7[i].length >= 5 ? last7[i].substring(5) : last7[i], style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [for (int i = 0; i < last7.length; i++) FlSpot(i.toDouble(), (revenueByDate[last7[i]] ?? 0).toDouble())],
                        isCurved: true,
                        color: MedEaseColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: MedEaseColors.primaryLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Appointments by department', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: apptsByDept.isEmpty
                    ? const Center(child: Text('No appointment data yet'))
                    : BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final keys = apptsByDept.keys.toList();
                            final i = v.toInt();
                            if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(keys[i].length > 6 ? keys[i].substring(0, 6) : keys[i], style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < apptsByDept.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: apptsByDept.values.elementAt(i).toDouble(),
                            color: MedEaseColors.accent,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Appointments by status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: apptsByStatus.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: MedEaseColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MedEaseColors.border),
                    ),
                    child: Column(
                      children: [
                        Text('${e.value}', style: Theme.of(context).textTheme.headlineMedium),
                        Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsData {
  final List<Bill> bills;
  final List<Doctor> doctors;
  final List<Appointment> appointments;
  _AnalyticsData({required this.bills, required this.doctors, required this.appointments});
}