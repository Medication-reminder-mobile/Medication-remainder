import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caregiver_provider.dart';

class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() => _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  bool _loaded = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final id = context.read<AuthProvider>().currentUser?.id;
    if (id == null) return;
    await context.read<CaregiverProvider>().loadLinkedPatients(id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaregiverProvider>();
    final q = _search.text.trim().toLowerCase();
    final patients = provider.linkedPatients.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.email.toLowerCase().contains(q);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Caregiver Patient List',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'View linked patients and jump into medication monitoring.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Link patient',
                  onPressed: () async {
                    await context.push('/caregiver/link');
                    if (!mounted) return;
                    await _load();
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && patients.isEmpty)
              ...List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Shimmer.fromColors(
                    baseColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232323) : const Color(0xFFE5E7EB),
                    highlightColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            if (!provider.isLoading && patients.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No linked patients yet. Use the add icon in search to link one.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ...patients.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/caregiver/patient-meds/${p.id ?? 0}'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                          child: const Icon(Icons.person_outline, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(p.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.push('/caregiver/link');
          if (!mounted) return;
          await _load();
        },
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }
}

