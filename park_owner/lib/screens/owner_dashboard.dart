import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';
import '../services/api_service.dart';
import 'owner_login_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final Color primary = AppColors.primary;
  final Color primaryLight = AppColors.primaryLight;
  final Color textDark = AppColors.textPrimary;
  final Color textGrey = AppColors.textSecondary;

  Map<String, dynamic>? _profile;
  List<dynamic> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await ApiService.getProfile();
      List<dynamic> slots = [];
      if (profile['society'] != null) {
        slots = await ApiService.getMySlots(profile['society'].toString(), profile['id'].toString());
      }
      setState(() {
        _profile = profile;
        _slots = slots;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
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

  void _showAddSlotModal() {
    final slotNumCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: _profile?['floor_number'] ?? '');
    final rateCtrl = TextEditingController();
    String slotType = 'car';
    TimeOfDay availableFrom = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay availableTo = const TimeOfDay(hour: 18, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 16),
              AppTextField(label: 'Slot Number', hint: 'e.g. A-101', controller: slotNumCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Floor', hint: 'e.g. 1st', controller: floorCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Car'),
                      value: 'car',
                      groupValue: slotType,
                      onChanged: (v) => setModalState(() => slotType = v.toString()),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Bike'),
                      value: 'bike',
                      groupValue: slotType,
                      onChanged: (v) => setModalState(() => slotType = v.toString()),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Hourly Rate (₹)', hint: 'e.g. 50', controller: rateCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Availability Timings', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('From: ${availableFrom.format(context)}'),
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: availableFrom);
                        if (time != null) setModalState(() => availableFrom = time);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('To: ${availableTo.format(context)}'),
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: availableTo);
                        if (time != null) setModalState(() => availableTo = time);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Submit for Approval',
                onPressed: () async {
                  if (slotNumCtrl.text.isEmpty || rateCtrl.text.isEmpty) return;
                  final rate = double.tryParse(rateCtrl.text) ?? 0.0;
                  
                  final formatTime = (TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                  
                  try {
                    await ApiService.addSlot(
                      societyId: _profile!['society'],
                      slotNumber: slotNumCtrl.text.trim(),
                      floor: floorCtrl.text.trim(),
                      slotType: slotType,
                      hourlyRate: rate,
                      availableFrom: formatTime(availableFrom),
                      availableTo: formatTime(availableTo),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: primary), child: const Text('Retry', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
    }

    final isApproved = _profile?['society'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: primary,
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight]),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resident Panel', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, letterSpacing: 0.5)),
                          Text(_profile?['full_name'] ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main Content ──
              Expanded(
                child: !isApproved 
                  ? _buildPendingState() 
                  : _buildSlotsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isApproved ? FloatingActionButton.extended(
        onPressed: _showAddSlotModal,
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildPendingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.hourglass_empty_rounded, size: 80, color: textGrey.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text('Pending Approval', style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Your society membership request is pending. Once the society admin approves your request, you will be able to manage your parking slots here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_parking_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text('My Parking Slots', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          if (_slots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.directions_car_filled_outlined, size: 60, color: textGrey.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No slots added yet', style: TextStyle(color: textGrey)),
                  ],
                ),
              ),
            ),
          ..._slots.map((slot) => _buildSlotCard(slot)).toList(),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final status = slot['approval_status'] ?? 'pending';
    final state = slot['state'] ?? 'blocked';
    
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.hourglass_bottom_rounded;
    if (status == 'approved') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(slot['slot_type'] == 'bike' ? Icons.pedal_bike_rounded : Icons.directions_car_rounded, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot['slot_number'] ?? 'Slot', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Floor: ${slot['floor'] ?? '-'}', style: TextStyle(color: textGrey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(status.toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('₹${slot['hourly_rate']}/hr', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          if (status == 'approved') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Current State: ', style: TextStyle(fontSize: 12)),
                Text(state.toString().toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: state == 'available' ? AppColors.success : Colors.orange)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}