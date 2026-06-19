import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../services/api_service.dart';
import 'owner_login_page.dart';
import 'qr_scanner_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ApiService.getProfile();
      List<dynamic> slots = [];
      if (profile['society'] != null) {
        slots = await ApiService.getMySlots(
          profile['society'].toString(),
          profile['id'].toString(),
        );
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

  Future<void> _toggleSlotActive(String slotId, bool currentIsActive) async {
    if (_profile == null || _profile!['society'] == null) return;
    
    // Optimistic UI update
    setState(() {
      final idx = _slots.indexWhere((s) => s['id'] == slotId);
      if (idx != -1) {
        _slots[idx]['is_active'] = !currentIsActive;
      }
    });
    
    try {
      await ApiService.toggleSlotActive(
        _profile!['society'].toString(),
        slotId,
        !currentIsActive,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        final idx = _slots.indexWhere((s) => s['id'] == slotId);
        if (idx != -1) {
          _slots[idx]['is_active'] = currentIsActive;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddSlotModal() {
    final slotNumCtrl = TextEditingController();
    final floorCtrl = TextEditingController(
      text: _profile?['floor_number'] ?? '',
    );
    final rateCtrl = TextEditingController();
    String slotType = 'car';
    TimeOfDay availableFrom = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay availableTo = const TimeOfDay(hour: 18, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ADD NEW SLOT',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'List your parking space',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Slot Number',
                hint: 'e.g. A-101',
                controller: slotNumCtrl,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Floor',
                hint: 'e.g. 1st',
                controller: floorCtrl,
              ),
              const SizedBox(height: 16),
              const Text(
                'VEHICLE TYPE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => slotType = 'car'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: slotType == 'car'
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: slotType == 'car'
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: slotType == 'car'
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => slotType = 'bike'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: slotType == 'bike'
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: slotType == 'bike'
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.pedal_bike_rounded,
                          color: slotType == 'bike'
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Hourly Rate (₹)',
                hint: 'e.g. 50',
                controller: rateCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AVAILABLE FROM',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: availableFrom,
                            );
                            if (time != null) {
                              setModalState(() => availableFrom = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  availableFrom.format(context),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.access_time_rounded,
                                    color: AppColors.textSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AVAILABLE TO',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: availableTo,
                            );
                            if (time != null) {
                              setModalState(() => availableTo = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  availableTo.format(context),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.access_time_rounded,
                                    color: AppColors.textSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Save Parking Slot',
                onPressed: () async {
                  if (slotNumCtrl.text.isEmpty ||
                      rateCtrl.text.isEmpty ||
                      floorCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  String formatTime(TimeOfDay t) {
                    final h = t.hour.toString().padLeft(2, '0');
                    final m = t.minute.toString().padLeft(2, '0');
                    return '$h:$m:00';
                  }

                  Navigator.pop(context);
                  setState(() => _loading = true);

                  try {
                    await ApiService.addSlot(
                      societyId: _profile!['society'].toString(),
                      slotNumber: slotNumCtrl.text.trim(),
                      floor: floorCtrl.text.trim(),
                      slotType: slotType,
                      hourlyRate: double.parse(rateCtrl.text.trim()),
                      availableFrom: formatTime(availableFrom),
                      availableTo: formatTime(availableTo),
                    );
                    _loadData();
                  } catch (e) {
                    setState(() {
                      _error = 'Failed to add slot: $e';
                      _loading = false;
                    });
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
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Retry',
                onPressed: _loadData,
              )
            ],
          ),
        ),
      );
    }

    final isApproved = _profile?['approval_status'] == 'approved';
    final approvedSlots =
        _slots.where((s) => s['approval_status'] == 'approved').length;
    final pendingSlots =
        _slots.where((s) => s['approval_status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // ── Header ──
              PremiumHeader(
                title: 'Hello, ${_profile?['full_name']?.split(' ')[0] ?? 'User'}',
                subtitle: '${_profile?['society_name'] ?? 'Society'} • Flat ${_profile?['flat_number'] ?? '-'}',
                actions: [
                  ListenableBuilder(
                    listenable: GetIt.I<ThemeNotifier>(),
                    builder: (context, _) {
                      final isDark = GetIt.I<ThemeNotifier>().isDark;
                      return GestureDetector(
                        onTap: GetIt.I<ThemeNotifier>().toggle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QRScannerPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isApproved) ...[
                      _buildPendingState(),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: PremiumMetricTile(
                              label: 'My Slots',
                              value: '${_slots.length}',
                              icon: Icons.local_parking_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PremiumMetricTile(
                              label: 'Approved',
                              value: '$approvedSlots',
                              icon: Icons.check_circle_outline_rounded,
                              valueColor: AppColors.success,
                            ),
                          ),
                          if (pendingSlots > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: PremiumMetricTile(
                                label: 'Pending',
                                value: '$pendingSlots',
                                icon: Icons.hourglass_top_rounded,
                                valueColor: AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MY PARKING SLOTS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              fontFamily: 'Inter',
                            ),
                          ),
                          GestureDetector(
                            onTap: _showAddSlotModal,
                            child: const Text(
                              '+ Add slot',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_slots.isEmpty)
                        _buildEmptySlots()
                      else
                        ..._slots.map((slot) => _SlotCard(
                              slot: slot as Map<String, dynamic>,
                              onToggleActive: _toggleSlotActive,
                            )),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isApproved
          ? FloatingActionButton.extended(
              onPressed: _showAddSlotModal,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Slot',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
            )
          : null,
    );
  }

  Widget _buildPendingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty_rounded,
                size: 40, color: AppColors.warning),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pending Approval',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your society membership request is pending. Once the admin approves your request, you can manage your slots here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlots() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const EmptyStateWidget(
        icon: Icons.local_parking_outlined,
        title: 'No slots added yet',
        subtitle: 'Tap "Add slot" to list your first parking space',
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  final void Function(String slotId, bool isActive) onToggleActive;

  const _SlotCard({required this.slot, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    final approvalStatus = slot['approval_status'] ?? 'pending';
    final slotState = slot['state'] ?? 'blocked';
    final isActive = slot['is_active'] ?? true;
    final nextFreeAtRaw = slot['next_free_at'];
    final freeingNote = slot['freeing_up_note'] as String?;
    final currentBookingNumber = slot['current_booking_number'] as String?;
    final currentBookingStatus = slot['current_booking_status'] as String?;
    final currentBookingEndTimeRaw =
        slot['current_booking_end_time'] as String?;
    final bookings = (slot['bookings'] as List<dynamic>?) ?? const [];
    final timeLabel = DateFormat('MMM d, hh:mm a');

    DateTime? nextFreeAt;
    DateTime? currentBookingEndTime;
    try {
      if (nextFreeAtRaw is String && nextFreeAtRaw.isNotEmpty) {
        nextFreeAt = DateTime.parse(nextFreeAtRaw).toLocal();
      }
      if (currentBookingEndTimeRaw != null &&
          currentBookingEndTimeRaw.isNotEmpty) {
        currentBookingEndTime =
            DateTime.parse(currentBookingEndTimeRaw).toLocal();
      }
    } catch (_) {}

    Color statusColor = AppColors.warning;
    IconData statusIcon = Icons.hourglass_top_rounded;
    if (approvalStatus == 'approved') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (approvalStatus == 'rejected') {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    slot['slot_type'] == 'bike'
                        ? Icons.pedal_bike_rounded
                        : Icons.directions_car_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot['slot_number'] ?? 'Slot',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Floor ${slot['floor'] ?? '-'} · ₹${slot['hourly_rate']}/hr',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (approvalStatus == 'approved')
                      Switch(
                        value: isActive,
                        onChanged: (val) => onToggleActive(slot['id'], isActive),
                        activeColor: AppColors.primaryLight,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        approvalStatus.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                if (approvalStatus == 'approved')
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: slotState == 'available'
                          ? AppColors.success
                          : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          if (approvalStatus == 'approved' && bookings.isNotEmpty) ...[
            Container(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UPCOMING BOOKINGS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...bookings.map((b) {
                    final bStatus = b['status'] ?? '';
                    final bStartStr = b['start_time'] ?? '';
                    final bEndStr = b['end_time'] ?? '';
                    String displayTime = '';
                    try {
                      if (bStartStr.isNotEmpty && bEndStr.isNotEmpty) {
                        final st = DateTime.parse(bStartStr).toLocal();
                        final en = DateTime.parse(bEndStr).toLocal();
                        displayTime =
                            '${timeLabel.format(st)} - ${DateFormat('hh:mm a').format(en)}';
                      }
                    } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['booking_number'] ?? 'Booking',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayTime,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.outline.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bStatus.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
