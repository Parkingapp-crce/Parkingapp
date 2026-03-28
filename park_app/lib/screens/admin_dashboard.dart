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
  // 🟠 Orange/Amber theme for Admin
  final Color primary = const Color(0xFFEA580C);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<dynamic> _parkingLots = [];
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getAdminDashboard(),
      ]);
      setState(() {
        _profile = results[0];
        _stats = results[1]['stats'];
        _parkingLots = results[1]['parking_lots'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LandingPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SafeArea(
              child: Column(
                children: [
                  // 🟠 Orange gradient header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFC2410C),
                          Color(0xFFEA580C),
                          Color(0xFFF97316),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Administrator',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                          letterSpacing: 0.5)),
                                  Text(_profile?['user']?['name'] ?? 'Admin',
                                      style: const TextStyle(color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Tab bar
                        Row(
                          children: [
                            _Tab(label: 'Overview', selected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0)),
                            const SizedBox(width: 8),
                            _Tab(label: 'Parking Lots', selected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1)),
                            const SizedBox(width: 8),
                            _Tab(label: 'System', selected: _selectedTab == 2,
                                onTap: () => setState(() => _selectedTab = 2)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _selectedTab == 0
                            ? _buildOverview()
                            : _selectedTab == 1
                                ? _buildParkingLots()
                                : _buildSystem(),
                      ),
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(label: 'Total Users',
                value: '${_stats?['total_users'] ?? '--'}',
                icon: Icons.people_rounded,
                color: const Color(0xFF2563EB)),
            _StatCard(label: 'Total Owners',
                value: '${_stats?['total_owners'] ?? '--'}',
                icon: Icons.business_rounded,
                color: primary),
            _StatCard(label: 'Parking Lots',
                value: '${_stats?['total_lots'] ?? '--'}',
                icon: Icons.local_parking_rounded,
                color: const Color(0xFF7C3AED)),
            _StatCard(label: 'Customers',
                value: '${_stats?['total_customers'] ?? '--'}',
                icon: Icons.person_rounded,
                color: const Color(0xFF059669)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildParkingLots() {
    if (_parkingLots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.local_parking_rounded,
                  color: primary.withOpacity(0.3), size: 60),
              const SizedBox(height: 16),
              Text('No parking lots registered yet.',
                  style: TextStyle(color: textGrey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _parkingLots.map((lot) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_parking_rounded,
                        color: primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(lot['name'] ?? '-',
                        style: TextStyle(color: textDark,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (lot['is_active'] == true)
                          ? const Color(0xFF059669).withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (lot['is_active'] == true) ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: (lot['is_active'] == true)
                              ? const Color(0xFF059669)
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text(lot['city'] ?? '-',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.currency_rupee_rounded, size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text('${lot['price_per_hour']}/hr',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.local_parking_rounded, size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text('${lot['available_slots']}/${lot['total_slots']} available',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.person_rounded, size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text(lot['owner_name'] ?? '-',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystem() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text('System Status',
                  style: TextStyle(color: textDark,
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _StatusRow(label: 'Django Backend', status: 'Online',
              ok: true, primary: primary, textGrey: textGrey),
          _StatusRow(label: 'Supabase DB', status: 'Connected',
              ok: true, primary: primary, textGrey: textGrey),
          _StatusRow(label: 'Email Service', status: 'Active',
              ok: true, primary: primary, textGrey: textGrey),
          _StatusRow(label: 'JWT Auth', status: 'Enabled',
              ok: true, primary: primary, textGrey: textGrey),
          _StatusRow(label: 'CORS', status: 'Configured',
              ok: true, primary: primary, textGrey: textGrey, isLast: true),
        ],
      ),
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
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFFEA580C) : Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: textDark,
                  fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Color get textDark => const Color(0xFF1B2236);
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool ok;
  final Color primary;
  final Color textGrey;
  final bool isLast;

  const _StatusRow({required this.label, required this.status, required this.ok,
      required this.primary, required this.textGrey, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok ? const Color(0xFF059669) : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label,
                  style: TextStyle(color: textGrey, fontSize: 13))),
              Text(status,
                  style: TextStyle(
                      color: ok ? const Color(0xFF059669) : Colors.red,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }
}
