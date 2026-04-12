import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'owner_login_page.dart';
import 'qr_scanner_page.dart';
import 'entry_logs_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final Color primary = const Color(0xFF2563EB);
  final Color primaryLight = const Color(0xFFEFF6FF);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _parkingLot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getOwnerDashboard(),
      ]);
      setState(() {
        _profile = results[0];
        _parkingLot = results[1]['parking_lot'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OwnerLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 56, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primary),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // ── Blue gradient header ──
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.fromLTRB(24, 24, 24, 28),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1D4ED8),
                                  Color(0xFF2563EB),
                                  Color(0xFF3B82F6),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Owner name + logout
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                          Icons.business_rounded,
                                          color: Colors.white,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Parking Owner',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                                letterSpacing: 0.5),
                                          ),
                                          Text(
                                            _profile?['user']?['name'] ??
                                                'Owner',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight:
                                                    FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _logout,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.2)),
                                        ),
                                        child: const Icon(
                                            Icons.logout_rounded,
                                            color: Colors.white,
                                            size: 18),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 28),

                                // Stats row
                                Row(
                                  children: [
                                    _HeaderStat(
                                      label: 'Total Slots',
                                      value:
                                          '${_parkingLot?['total_slots'] ?? 0}',
                                      icon: Icons.local_parking_rounded,
                                    ),
                                    Container(
                                        width: 1,
                                        height: 40,
                                        color:
                                            Colors.white.withOpacity(0.2)),
                                    _HeaderStat(
                                      label: 'Occupied',
                                      value:
                                          '${(_parkingLot?['total_slots'] ?? 0) - (_parkingLot?['available_slots'] ?? 0)}',
                                      icon: Icons.directions_car_rounded,
                                    ),
                                    Container(
                                        width: 1,
                                        height: 40,
                                        color:
                                            Colors.white.withOpacity(0.2)),
                                    _HeaderStat(
                                      label: 'Available',
                                      value:
                                          '${_parkingLot?['available_slots'] ?? 0}',
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Parking lot details ──
                                Row(
                                  children: [
                                    Icon(Icons.local_parking_rounded,
                                        color: primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Parking Lot Details',
                                        style: TextStyle(
                                            color: textDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _InfoRow(
                                          icon: Icons.business_rounded,
                                          label: 'Name',
                                          value:
                                              _parkingLot?['name'] ?? '-',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark),
                                      _InfoRow(
                                          icon: Icons.location_on_rounded,
                                          label: 'Address',
                                          value: _parkingLot?['address'] ??
                                              '-',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark),
                                      _InfoRow(
                                          icon:
                                              Icons.location_city_rounded,
                                          label: 'City',
                                          value:
                                              _parkingLot?['city'] ?? '-',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark),
                                      _InfoRow(
                                          icon:
                                              Icons.currency_rupee_rounded,
                                          label: 'Price/hr',
                                          value:
                                              '₹${_parkingLot?['price_per_hour'] ?? 0}',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark),
                                      _InfoRow(
                                          icon: Icons.access_time_rounded,
                                          label: 'Hours',
                                          value:
                                              '${_parkingLot?['opening_time'] ?? '--'} - ${_parkingLot?['closing_time'] ?? '--'}',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark),
                                      _InfoRow(
                                          icon: Icons.circle,
                                          label: 'Status',
                                          value: (_parkingLot?[
                                                      'is_active'] ==
                                                  true)
                                              ? 'Active ✅'
                                              : 'Inactive ❌',
                                          primary: primary,
                                          textGrey: textGrey,
                                          textDark: textDark,
                                          isLast: true),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Quick Actions ──
                                Row(
                                  children: [
                                    Icon(Icons.grid_view_rounded,
                                        color: primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Quick Actions',
                                        style: TextStyle(
                                            color: textDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.5,
                                  children: [
                                    // ✅ SCAN QR
                                    _ActionCard(
                                      icon: Icons.qr_code_scanner_rounded,
                                      label: 'Scan QR',
                                      color: primary,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const QRScannerPage()),
                                      ),
                                    ),
                                    // ✅ ENTRY LOGS
                                    _ActionCard(
                                      icon: Icons.history_rounded,
                                      label: 'Entry Logs',
                                      color: const Color(0xFF059669),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const EntryLogsPage()),
                                      ),
                                    ),
                                    // Bookings (future)
                                    _ActionCard(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'Bookings',
                                      color: const Color(0xFF7C3AED),
                                      onTap: () {},
                                    ),
                                    // Settings (future)
                                    _ActionCard(
                                      icon: Icons.settings_rounded,
                                      label: 'Settings',
                                      color: textGrey,
                                      onTap: () {},
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _HeaderStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;
  final Color textGrey;
  final Color textDark;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.textGrey,
    required this.textDark,
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
              Icon(icon, color: primary, size: 18),
              const SizedBox(width: 12),
              Text('$label: ',
                  style: TextStyle(color: textGrey, fontSize: 13)),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Icon(icon, color: color, size: 22),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}