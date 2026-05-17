import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/menu_helpers.dart';

import '../../core/constants/app_colors.dart';
import '../../models/medication_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/pill_icon_widget.dart';

class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  bool _loaded = false;
  // FIX: search controller now properly triggers setState via listener
  final _search = TextEditingController();
  String _filter = 'All';

  final _filters = ['All', 'Daily', 'Weekly', 'As Needed'];

  @override
  void initState() {
    super.initState();
    // FIX: attach listener so search bar actually filters results
    _search.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<MedicationProvider>().loadMedications(userId);
    if (!mounted) return;
    final err = context.read<MedicationProvider>().errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  List<MedicationModel> _filtered(List<MedicationModel> meds) {
    final q = _search.text.trim().toLowerCase();
    return meds.where((m) {
      final matchSearch = q.isEmpty || m.name.toLowerCase().contains(q);
      final matchFilter =
          _filter == 'All' ||
          (_filter == 'Daily' && m.frequency.toLowerCase() == 'daily') ||
          (_filter == 'Weekly' && m.frequency.toLowerCase() == 'weekly') ||
          (_filter == 'As Needed' && m.frequency.toLowerCase() == 'as needed');
      return matchSearch && matchFilter;
    }).toList();
  }

  // FIX: delete with undo snackbar — no more crash or black screen
  Future<void> _deleteMed(MedicationModel med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Remove ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.missedAlert),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await context.read<MedicationProvider>().deleteMedication(med.id!);
    if (!mounted) return;

    final err = context.read<MedicationProvider>().errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    // FIX: show undo snackbar — tapping Undo re-inserts the medication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<MedicationProvider>().undoDelete();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // FIX: toggle active/inactive directly from list
  Future<void> _toggleStatus(MedicationModel med) async {
    final newStatus = med.status == 'paused' ? 'active' : 'paused';
    await context.read<MedicationProvider>().toggleStatus(med.id!, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${med.name} ${newStatus == 'active' ? 'activated' : 'paused'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final meds = _filtered(provider.medications);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => showAppMenu(context),
        ),
        title: const Text('MedRemind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            onPressed: () => context.go('/voice'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Medications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Stay on track with your health journey.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // FIX: search bar now works — listener attached in initState
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search medications...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      // FIX: add clear button when there is text
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading && provider.medications.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Shimmer.fromColors(
                          baseColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF232323)
                              : const Color(0xFFE5E7EB),
                          highlightColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFF3F4F6),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    )
                  : meds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: AppColors.inactiveUpcoming.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No medications found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/meds/add'),
                            child: const Text('Add your first medication'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: meds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _MedTile(
                        med: meds[i],
                        onDelete: () => _deleteMed(meds[i]),
                        // FIX: pass toggle callback so active/inactive works
                        onToggleStatus: () => _toggleStatus(meds[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/meds/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MedTile extends StatelessWidget {
  const _MedTile({
    required this.med,
    required this.onDelete,
    required this.onToggleStatus,
  });
  final MedicationModel med;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final paused = med.status == 'paused';
    final statusColor = paused ? AppColors.inactiveUpcoming : AppColors.primary;

    return Semantics(
      button: true,
      label: 'Medication ${med.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/meds/detail/${med.id ?? 0}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 2),
                color: Colors.black12,
              ),
            ],
          ),
          child: Row(
            children: [
              PillIcon(
                shape: med.pillShape,
                colorHex: med.pillColor,
                size: 32,
                semanticsLabel: 'Pill icon',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // FIX: status badge is now tappable to toggle active/paused
                        GestureDetector(
                          onTap: onToggleStatus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  paused ? 'PAUSED' : 'ACTIVE',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  paused
                                      ? Icons.pause_circle_outline
                                      : Icons.check_circle_outline,
                                  size: 12,
                                  color: statusColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${med.dosageStrength}${med.dosageUnit} • ${med.frequency}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (med.scheduledTimes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${med.scheduledTimes.first}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Medication options',
                onSelected: (v) {
                  if (v == 'edit') context.go('/meds/edit/${med.id ?? 0}');
                  if (v == 'delete') onDelete();
                  if (v == 'toggle') onToggleStatus();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          paused
                              ? Icons.play_circle_outline
                              : Icons.pause_circle_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(paused ? 'Activate' : 'Pause'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: AppColors.missedAlert,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.missedAlert),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
