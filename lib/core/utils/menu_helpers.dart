import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';

void showAppMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Navigation'),
            subtitle: Text('Quick access to app pages'),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: const Text('Meds'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.meds);
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: const Text('Log'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.log);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.reports);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bloodtype_outlined),
            title: const Text('RBC'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.rbc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('Voice Assistant'),
            onTap: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.voice);
            },
          ),
        ],
      ),
    ),
  );
}
