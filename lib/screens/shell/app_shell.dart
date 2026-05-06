import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/meds')) return 1;
    if (location.startsWith('/log')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/rbc')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _go(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/meds');
      case 2:
        context.go('/log');
      case 3:
        context.go('/reports');
      case 4:
        context.go('/rbc');
      case 5:
        context.go('/profile');
      default:
        context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _indexFromLocation(location);
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role ?? '';

    return Scaffold(
      body: child,
      bottomNavigationBar: Semantics(
        label: 'Bottom navigation',
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => _go(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              label: 'Meds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype_outlined),
              label: 'RBC',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: (role == 'individual_user' && idx == 0) || idx == 1
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => context.go('/meds/add'),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
