import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'landing_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.getProfile();
    setState(() {
      _profile = response;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                _profile?['user']?['name'] ?? 'Owner',
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: Colors.white54, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Stats row
                    Row(
                      children: [
                        _StatCard(label: 'Total Slots', value: '24',
                            color: const Color(0xFF7C4DFF)),
                        const SizedBox(width: 12),
                        _StatCard(label: 'Occupied', value: '12',
                            color: const Color(0xFFFF6D00)),
                        const SizedBox(width: 12),
                        _StatCard(label: 'Available', value: '12',
                            color: const Color(0xFF00E5FF)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Lot info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF7C4DFF).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_parking_rounded,
                                  color: Color(0xFF7C4DFF), size: 20),
                              const SizedBox(width: 8),
                              const Text('Your Parking Lot',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(icon: Icons.business_rounded,
                              label: 'Name', value: 'My Parking Lot'),
                          _InfoRow(icon: Icons.location_on_rounded,
                              label: 'Address', value: 'Your address here'),
                          _InfoRow(icon: Icons.attach_money_rounded,
                              label: 'Price/hr', value: '₹50'),
                          _InfoRow(icon: Icons.access_time_rounded,
                              label: 'Hours', value: '08:00 - 22:00'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick actions
                    const Text('Quick Actions',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'View Bookings',
                            color: const Color(0xFF7C4DFF),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.edit_rounded,
                            label: 'Edit Lot',
                            color: const Color(0xFF00E5FF),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'Revenue',
                            color: const Color(0xFFFF6D00),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            color: Colors.white24,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 26,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 16),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.4),
              fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
