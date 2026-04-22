import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color primary = const Color(0xFFEA580C);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _penaltyPolicy;
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

      if (!mounted) return;
      setState(() {
        _profile = results[0];
        _stats = results[1]['stats'] as Map<String, dynamic>?;
        _penaltyPolicy = results[1]['penalty_policy'] as Map<String, dynamic>?;
        _parkingLots = results[1]['parking_lots'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _formatCurrency(dynamic value) {
    final amount = _asDouble(value);
    final whole = amount.truncateToDouble() == amount;
    return '₹${amount.toStringAsFixed(whole ? 0 : 2)}';
  }

  String _formatRule(String? rule) {
    if (rule == null || rule.isEmpty) return 'Not configured';
    return rule.replaceFirst('Rs ', '₹');
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
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Administrator',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _profile?['user']?['name'] ?? 'Admin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _Tab(
                              label: 'Overview',
                              selected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                            const SizedBox(width: 8),
                            _Tab(
                              label: 'Parking Lots',
                              selected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                            const SizedBox(width: 8),
                            _Tab(
                              label: 'System',
                              selected: _selectedTab == 2,
                              onTap: () => setState(() => _selectedTab = 2),
                            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _StatCard(
              label: 'Monthly Earnings',
              value: _formatCurrency(_stats?['monthly_earnings']),
              subtitle:
                  '${_asInt(_stats?['completed_bookings'])} completed exits',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF059669),
            ),
            _StatCard(
              label: 'Total Earnings',
              value: _formatCurrency(_stats?['total_earnings']),
              subtitle: '${_asInt(_stats?['total_bookings'])} paid bookings',
              icon: Icons.payments_rounded,
              color: primary,
            ),
            _StatCard(
              label: 'Active Sessions',
              value: '${_asInt(_stats?['active_sessions'])}',
              subtitle: 'Vehicles currently inside',
              icon: Icons.local_parking_rounded,
              color: const Color(0xFF2563EB),
            ),
            _StatCard(
              label: 'Overstay Alerts',
              value: '${_asInt(_stats?['overstay_alerts'])}',
              subtitle: 'Sessions past end time',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Revenue Snapshot',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricPanel(
                      label: 'Monthly Penalties',
                      value: _formatCurrency(_stats?['monthly_penalties']),
                      hint: 'Current month',
                      tone: const Color(0xFFFEF3C7),
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricPanel(
                      label: 'Penalties Collected',
                      value: _formatCurrency(_stats?['penalties_collected']),
                      hint: 'Lifetime total',
                      tone: const Color(0xFFFEE2E2),
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricPanel(
                      label: 'Owners',
                      value: '${_asInt(_stats?['total_owners'])}',
                      hint: 'Registered partners',
                      tone: primary.withOpacity(0.08),
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricPanel(
                      label: 'Customers',
                      value: '${_asInt(_stats?['total_customers'])}',
                      hint: 'End users onboarded',
                      tone: const Color(0xFFDBEAFE),
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Penalty Policy',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  _Chip(
                    label: (_penaltyPolicy?['enabled'] == true)
                        ? 'Enabled'
                        : 'Disabled',
                    color: (_penaltyPolicy?['enabled'] == true)
                        ? const Color(0xFF059669)
                        : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatRule(_penaltyPolicy?['rule'] as String?),
                style: TextStyle(color: textGrey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                (_penaltyPolicy?['exit_scan_required'] == true)
                    ? 'Exit scans are required so overstays can be calculated before checkout.'
                    : 'Exit scans are optional.',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
              Icon(
                Icons.local_parking_rounded,
                color: primary.withOpacity(0.3),
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'No parking lots registered yet.',
                style: TextStyle(color: textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _parkingLots.map((lot) {
        final isActive = lot['is_active'] == true;
        final overstayAlerts = _asInt(lot['overstay_alerts']);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
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
                    child: Icon(
                      Icons.local_parking_rounded,
                      color: primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lot['name'] ?? '-',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _Chip(
                    label: isActive ? 'Active' : 'Inactive',
                    color: isActive ? const Color(0xFF059669) : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _InlineInfo(
                    icon: Icons.location_on_rounded,
                    text: lot['city'] ?? '-',
                    textGrey: textGrey,
                  ),
                  _InlineInfo(
                    icon: Icons.currency_rupee_rounded,
                    text: '${lot['price_per_hour']}/hr',
                    textGrey: textGrey,
                  ),
                  _InlineInfo(
                    icon: Icons.person_rounded,
                    text: lot['owner_name'] ?? '-',
                    textGrey: textGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LotMetric(
                      label: 'Monthly',
                      value: _formatCurrency(lot['monthly_earnings']),
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LotMetric(
                      label: 'Total',
                      value: _formatCurrency(lot['total_earnings']),
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LotMetric(
                      label: 'Active Sessions',
                      value: '${_asInt(lot['active_sessions'])}',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LotMetric(
                      label: 'Overstay Alerts',
                      value: '$overstayAlerts',
                      color: overstayAlerts > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${lot['available_slots']}/${lot['total_slots']} slots available right now',
                style: TextStyle(color: textGrey, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystem() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'System Status',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusRow(
                label: 'Django Backend',
                status: 'Online',
                ok: true,
                primary: primary,
                textGrey: textGrey,
              ),
              _StatusRow(
                label: 'Admin Analytics',
                status: 'Live revenue stats',
                ok: true,
                primary: primary,
                textGrey: textGrey,
              ),
              _StatusRow(
                label: 'Penalty Engine',
                status: (_penaltyPolicy?['enabled'] == true)
                    ? 'Enabled'
                    : 'Disabled',
                ok: _penaltyPolicy?['enabled'] == true,
                primary: primary,
                textGrey: textGrey,
              ),
              _StatusRow(
                label: 'Exit Scan Flow',
                status: (_penaltyPolicy?['exit_scan_required'] == true)
                    ? 'Required'
                    : 'Optional',
                ok: _penaltyPolicy?['exit_scan_required'] == true,
                primary: primary,
                textGrey: textGrey,
              ),
              _StatusRow(
                label: 'Overstay Monitoring',
                status: '${_asInt(_stats?['overstay_alerts'])} live alerts',
                ok: true,
                primary: primary,
                textGrey: textGrey,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Overstay Handling Works',
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '1. First scan checks the vehicle in.\n2. Second scan records exit.\n3. If exit happens after the booking end time, a penalty is added automatically.',
                style: TextStyle(color: textGrey, fontSize: 13, height: 1.5),
              ),
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

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFEA580C) : Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1B2236),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color tone;
  final Color color;

  const _MetricPanel({
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1B2236),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textGrey;

  const _InlineInfo({
    required this.icon,
    required this.text,
    required this.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: textGrey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: textGrey, fontSize: 12)),
      ],
    );
  }
}

class _LotMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LotMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1B2236),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
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
  final Color primary;
  final Color textGrey;
  final bool isLast;

  const _StatusRow({
    required this.label,
    required this.status,
    required this.ok,
    required this.primary,
    required this.textGrey,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok ? const Color(0xFF059669) : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: textGrey, fontSize: 13),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: ok ? const Color(0xFF059669) : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }
}
