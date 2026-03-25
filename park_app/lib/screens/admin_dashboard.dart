import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'landing_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.getProfile();
    setState(() { _profile = response; _loading = false; });
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF6D00).withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Color(0xFFFF6D00), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Panel',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12)),
                              Text(_profile?['user']?['name'] ?? 'Admin',
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 16)),
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
                                color: Colors.white54, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _Tab(label: 'Overview', selected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0)),
                        const SizedBox(width: 8),
                        _Tab(label: 'Users', selected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1)),
                        const SizedBox(width: 8),
                        _Tab(label: 'Owners', selected: _selectedTab == 2,
                            onTap: () => setState(() => _selectedTab = 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _selectedTab == 0
                          ? _buildOverview()
                          : _selectedTab == 1
                              ? _buildUsers()
                              : _buildOwners(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview() {
    return Column(
      children: [
        // Stats grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: const [
            _AdminStatCard(label: 'Total Users', value: '--',
                icon: Icons.people_rounded, color: Color(0xFF00E5FF)),
            _AdminStatCard(label: 'Total Owners', value: '--',
                icon: Icons.business_rounded, color: Color(0xFF7C4DFF)),
            _AdminStatCard(label: 'Parking Lots', value: '--',
                icon: Icons.local_parking_rounded, color: Color(0xFFFF6D00)),
            _AdminStatCard(label: 'Bookings Today', value: '--',
                icon: Icons.calendar_today_rounded, color: Color(0xFF00E5B0)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('System Status',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              _StatusRow(label: 'Django Backend', status: 'Online', ok: true),
              _StatusRow(label: 'Supabase DB', status: 'Connected', ok: true),
              _StatusRow(label: 'Email Service', status: 'Active', ok: true),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUsers() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registered Customers',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              Text('User management coming in Phase 10.',
                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwners() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registered Owners',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              Text('Owner management coming in Phase 10.',
                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF6D00) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFFFF6D00)
                  : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 24,
                  fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool ok;

  const _StatusRow({required this.label, required this.status, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? const Color(0xFF00E5B0) : Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13))),
          Text(status, style: TextStyle(
              color: ok ? const Color(0xFF00E5B0) : Colors.red,
              fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
