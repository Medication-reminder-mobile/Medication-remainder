import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
 
import 'core/constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/caregiver/caregiver_dashboard_screen.dart';
import 'screens/caregiver/caregiver_link_screen.dart';
import 'screens/caregiver/caregiver_patient_meds_screen.dart';
import 'screens/caregiver/caregiver_patients_screen.dart';
import 'screens/meds/meds_add_screen.dart';
import 'screens/meds/meds_detail_screen.dart';
import 'screens/meds/meds_edit_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/rbc/rbc_dashboard_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/tabs/log_screen.dart';
import 'screens/tabs/meds_screen.dart';
import 'screens/tabs/profile_screen.dart';
import 'screens/tabs/reports_screen.dart';
import 'screens/voice/voice_screen.dart';
 
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ── Main tabs ──────────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) {
              final role = auth.currentUser?.role ?? '';
              if (role == 'individual_user') {
                return const PatientDashboardScreen();
              }
              return const CaregiverDashboardScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.meds,
            builder: (context, state) => const MedsScreen(),
          ),
          GoRoute(
            path: AppRoutes.log,
            builder: (context, state) => const LogScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.rbc,
            builder: (context, state) => const RbcDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.voice,
            builder: (context, state) => const VoiceScreen(),
          ),
 
          // ── Medication screens (kept inside ShellRoute so AppShell /
          //    bottom nav / back navigation all work correctly) ──────────
          GoRoute(
            path: AppRoutes.medsAdd,
            builder: (context, state) => const MedsAddScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.medsDetail}/:id',
            builder: (context, state) => MedsDetailScreen(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
          GoRoute(
            path: '${AppRoutes.medsEdit}/:id',
            builder: (context, state) => MedsEditScreen(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
 
          // ── Caregiver screens (also inside ShellRoute) ────────────────
          GoRoute(
            path: AppRoutes.caregiverPatients,
            builder: (context, state) => const CaregiverPatientsScreen(),
          ),
          GoRoute(
            path: AppRoutes.caregiverLink,
            builder: (context, state) => const CaregiverLinkScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.caregiverPatientMeds}/:patientId',
            builder: (context, state) => CaregiverPatientMedsScreen(
              patientId:
                  int.tryParse(state.pathParameters['patientId'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final role = auth.currentUser?.role ?? '';
      final loc = state.uri.toString();
 
      // Never redirect away from splash — it handles itself
      if (loc.startsWith(AppRoutes.splash)) return null;
 
      // Auth flow pages are always accessible when not logged in
      final isAuthFlow =
          loc.startsWith(AppRoutes.onboarding) ||
          loc.startsWith(AppRoutes.auth) ||
          loc.startsWith(AppRoutes.roleSelect);
 
      if (!loggedIn && !isAuthFlow) return AppRoutes.auth;
 
      // Logged in but no role yet → role selection
      if (loggedIn && role.isEmpty && !loc.startsWith(AppRoutes.roleSelect)) {
        return AppRoutes.roleSelect;
      }
 
      // Logged in with role → redirect away from auth/onboarding/role-select
      if (loggedIn && role.isNotEmpty && isAuthFlow) {
        return AppRoutes.home;
      }
 
      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
}