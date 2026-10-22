import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'doctor_home.dart';
import 'patient_history_screen.dart';
import '../shared/profile_screen.dart';

/// Bottom-nav shell for the Doctor role — Queue, History, Profile.
class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _index = 0;

  final _screens = const [
    DoctorHome(),
    PatientHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: MedEaseColors.surface,
        indicatorColor: MedEaseColors.primaryLight,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.queue_outlined), selectedIcon: Icon(Icons.queue_rounded), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
