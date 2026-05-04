import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0;

  final List<_MedicationEntry> _schedule = const [
    _MedicationEntry(
      name: 'Vitamin D',
      subtitle: 'Morning • 8:00 AM',
      status: 'Taken',
      icon: Icons.link_rounded,
      statusColor: Color(0xFF26D7B9),
    ),
    _MedicationEntry(
      name: 'Omega 3',
      subtitle: 'Morning • 8:00 AM',
      status: 'Taken',
      icon: Icons.medication_rounded,
      statusColor: Color(0xFF26D7B9),
    ),
    _MedicationEntry(
      name: 'Lisinopril',
      subtitle: 'Noon • 12:30 PM',
      status: 'Soon',
      icon: Icons.link_rounded,
      statusColor: Color(0xFFAFC2FF),
    ),
    _MedicationEntry(
      name: 'Metformin',
      subtitle: 'Evening • 8:00 PM',
      status: 'Scheduled',
      icon: Icons.nightlight_round,
      statusColor: Color(0xFF7D879E),
      isDimmed: true,
    ),
  ];

  void _goToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  void _logout() {
    AuthService.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const surface = Color(0xFF020A1E);
    const border = Color(0xFF14223D);
    const card = Color(0xFF071C3C);
    const brightBlue = Color(0xFF2D66F3);
    final takenCount = _schedule.where((entry) => entry.status == 'Taken').length;

    return Scaffold(
      backgroundColor: surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: brightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: AuthService.instance.refreshCurrentUser,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 88),
            children: [
              _TopBar(
                userName: user.name,
                onProfileTap: _goToProfile,
                onLogoutTap: _logout,
              ),
              const SizedBox(height: 12),
              _DateHeader(selectedDate: _selectedDate),
              const SizedBox(height: 16),
              _DateStrip(selectedDate: _selectedDate),
              const SizedBox(height: 20),
              const _NextDoseCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Medication Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$takenCount of ${_schedule.length} Taken',
                    style: const TextStyle(
                      color: Color(0xFF26D7B9),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in _schedule) ...[
                _MedicationCard(entry: entry, borderColor: border, cardColor: card),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              const _InsightsRow(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          if (index == 3) {
            _goToProfile();
            return;
          }
          setState(() => _selectedTab = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF071533),
        selectedItemColor: const Color(0xFF3E7BFF),
        unselectedItemColor: const Color(0xFF8D99B5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.link_rounded), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userName,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final initials = userName.trim().isEmpty
        ? '?'
        : userName.trim().substring(0, 1).toUpperCase();

    return Row(
      children: [
        CircleAvatar(radius: 16, child: Text(initials, style: const TextStyle(fontSize: 12))),
        const SizedBox(width: 10),
        const Text(
          'MedTracker',
          style: TextStyle(
            color: Color(0xFF59A4FF),
            fontStyle: FontStyle.italic,
            fontSize: 24 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF9FB2D8)),
        ),
        IconButton(
          tooltip: userName,
          onPressed: onProfileTap,
          icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF9FB2D8)),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogoutTap,
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF9FB2D8)),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Meds",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${monthNames[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year % 100}',
          style: const TextStyle(
            color: Color(0xFF4FA6FF),
            fontSize: 17 / 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final now = selectedDate;
    final days = List.generate(5, (i) => now.subtract(Duration(days: 2 - i)));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.day == now.day;
          return Container(
            width: 50,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2D66F3) : const Color(0xFF0D1A34),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A2E54)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labels[(day.weekday - 1) % 7],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF7D8AA8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFD7E1F8),
                    fontSize: 22 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF214DCB), Color(0xFF2E62D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Dose',
            style: TextStyle(color: Color(0xFFE0E9FF), letterSpacing: 1.3, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lisinopril, 10mg',
            style: TextStyle(color: Colors.white, fontSize: 40 / 2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scheduled for 12:30 PM',
            style: TextStyle(color: Color(0xFFD9E5FF), fontSize: 15),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 108,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF83A1E8).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA8BAEE)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('STARTS IN', style: TextStyle(color: Color(0xFFE3EBFF), fontSize: 11, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('02:45', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF6B89DE), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2454CF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('Take Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF6E8EE7)),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('Snooze'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsRow extends StatelessWidget {
  const _InsightsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1A3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1D315C)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.monitor_heart_outlined, color: Color(0xFF8FA8D9)),
                SizedBox(height: 26),
                Text('94%', style: TextStyle(color: Colors.white, fontSize: 34 / 2, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('WEEKLY ADHERENCE', style: TextStyle(color: Color(0xFF7E90B2), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002534),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00506E)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_services_outlined, color: Color(0xFF45E4C5)),
                SizedBox(height: 26),
                Text('2 Days', style: TextStyle(color: Colors.white, fontSize: 34 / 2, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('UNTIL REFILL', style: TextStyle(color: Color(0xFF27CBAE), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.entry,
    required this.borderColor,
    required this.cardColor,
  });

  final _MedicationEntry entry;
  final Color borderColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: entry.isDimmed ? 0.48 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              entry.icon,
              color: entry.statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    color: entry.isDimmed ? const Color(0xFF7883A0) : Colors.white,
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: TextStyle(color: entry.isDimmed ? const Color(0xFF5D6884) : const Color(0xFF98A7C8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: entry.statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.status,
              style: TextStyle(color: entry.statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationEntry {
  const _MedicationEntry({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.statusColor,
    this.isDimmed = false,
  });

  final String name;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color statusColor;
  final bool isDimmed;
}
