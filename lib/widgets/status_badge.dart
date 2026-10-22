import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color _colorFor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'done':
      case 'active':
        return MedEaseColors.success;
      case 'pending':
      case 'waiting':
      case 'booked':
        return MedEaseColors.warning;
      case 'cancelled':
      case 'inactive':
        return MedEaseColors.danger;
      default:
        return MedEaseColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
