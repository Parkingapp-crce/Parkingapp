import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../cubits/dashboard_cubit.dart';
import '../models/admin_dashboard_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _joinCode;
  bool _isJoinCodeLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadJoinCodeFromProfile();
      }
    });
    context.read<DashboardCubit>().startPolling();
  }

  void _loadData() {
    context.read<DashboardCubit>().loadDashboard();
  }

  Future<void> _loadJoinCodeFromProfile() async {
    setState(() => _isJoinCodeLoading = true);
    try {
      final response = await context.read<ApiClient>().get(ApiEndpoints.profile);
      final data = response.data;
      final societyId = data is Map<String, dynamic> ? data['society'] as String? : null;
      if (societyId == null || societyId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _joinCode = null;
          _isJoinCodeLoading = false;
        });
        return;
      }

      await _loadJoinCode(societyId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _joinCode = null;
        _isJoinCodeLoading = false;
      });
    }
  }

  Future<void> _loadJoinCode(String societyId) async {
    setState(() => _isJoinCodeLoading = true);
    try {
      final response = await context.read<ApiClient>().get(
        ApiEndpoints.society(societyId),
      );
      final data = response.data;
      if (!mounted) return;
      setState(() {
        _joinCode = data is Map<String, dynamic>
            ? data['join_code'] as String?
            : null;
        _isJoinCodeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _joinCode = null;
        _isJoinCodeLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.isLoading && state.dashboard == null) {
              return const LoadingWidget(message: 'Loading dashboard...');
            }

            if (state.error != null && state.dashboard == null) {
              return AppErrorWidget(message: state.error!, onRetry: _loadData);
            }

            final dashboard = state.dashboard;
            if (dashboard == null) {
              return const EmptyStateWidget(
                title: 'No dashboard data',
                subtitle: 'Society activity will appear here.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  PremiumHeader(
                    title: 'Society Dashboard',
                    subtitle: 'Operational control and metrics center',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () => context.go('/notifications'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _loadData,
                      ),
                      ListenableBuilder(
                        listenable: GetIt.I<ThemeNotifier>(),
                        builder: (context, _) {
                          final isDark = GetIt.I<ThemeNotifier>().isDark;
                          return IconButton(
                            icon: Icon(isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded),
                            onPressed: GetIt.I<ThemeNotifier>().toggle,
                            tooltip: isDark ? 'Light mode' : 'Dark mode',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () {
                          context.read<AuthBloc>().add(const AuthLoggedOut());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AdminActionsCard(
                    joinCode: dashboard.joinCode.isNotEmpty ? dashboard.joinCode : _joinCode,
                    isJoinCodeLoading: _isJoinCodeLoading,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Today at a glance',
                    subtitle: 'Current operational metrics and status summary',
                  ),
                  const SizedBox(height: 16),
                  _SummaryGrid(dashboard: dashboard),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Currently Parked',
                    subtitle:
                        '${dashboard.currentlyParked.length} active vehicle(s) inside the society',
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.currentlyParked.isEmpty)
                    const _EmptyCard(
                      'No vehicles are currently marked as parked.',
                    )
                  else
                    ...dashboard.currentlyParked.map(
                      (booking) => _ParkedVehicleCard(booking: booking),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Recent Gate Activity',
                    subtitle: 'Latest entry and exit scans from guards',
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.recentGateActivity.isEmpty)
                    const _EmptyCard('No gate activity has been recorded yet.')
                  else
                    ...dashboard.recentGateActivity.map(
                      (activity) => _GateActivityCard(activity: activity),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  final String? joinCode;
  final bool isJoinCodeLoading;

  const _AdminActionsCard({
    required this.joinCode,
    required this.isJoinCodeLoading,
  });

  @override
  Widget build(BuildContext context) {
    final displayCode = isJoinCodeLoading
        ? 'Loading...'
        : (joinCode?.isNotEmpty == true ? joinCode! : 'Unavailable');

    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.vpn_key_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Society Join Code',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayCode,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy code',
                onPressed: joinCode?.isNotEmpty == true
                    ? () async {
                        await Clipboard.setData(
                          ClipboardData(text: joinCode!),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Join code copied')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1.0, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionButton(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Join Requests',
                  onPressed: () => context.go('/join-requests'),
                ),
                _ActionButton(
                  icon: Icons.security_rounded,
                  label: 'Manage Guards',
                  onPressed: () => context.go('/guards'),
                ),
                _ActionButton(
                  icon: Icons.people_alt_rounded,
                  label: 'Owners',
                  onPressed: () => context.go('/owners'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final AdminDashboardModel dashboard;

  const _SummaryGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        PremiumMetricTile(
          label: 'Total Slots',
          value: dashboard.totalSlots.toString(),
          icon: Icons.local_parking_rounded,
        ),
        PremiumMetricTile(
          label: 'Occupied Slots',
          value: dashboard.occupiedSlots.toString(),
          icon: Icons.directions_car_rounded,
        ),
        PremiumMetricTile(
          label: 'Reserved Slots',
          value: dashboard.reservedSlots.toString(),
          icon: Icons.schedule_rounded,
        ),
        PremiumMetricTile(
          label: 'Active Bookings',
          value: dashboard.activeBookings.toString(),
          icon: Icons.book_online_rounded,
        ),
        PremiumMetricTile(
          label: 'Guard Requests',
          value: dashboard.pendingGuardRequests.toString(),
          icon: Icons.security_rounded,
        ),
        PremiumMetricTile(
          label: 'Completed Today',
          value: dashboard.completedToday.toString(),
          icon: Icons.task_alt_rounded,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ParkedVehicleCard extends StatelessWidget {
  final BookingModel booking;

  const _ParkedVehicleCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.vehicle?.registrationNo ?? 'Unknown vehicle',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PremiumBadge(
                label: booking.paymentStatusLabel,
                status: booking.paymentStatus,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1.0, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner',
            value: booking.ownerName ?? '-',
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: booking.ownerPhone ?? '-',
          ),
          _InfoRow(
            icon: Icons.local_parking_outlined,
            label: 'Slot',
            value: booking.slotNumber ?? '-',
          ),
          _InfoRow(
            icon: Icons.login_rounded,
            label: 'Entry Time',
            value: _formatDateTime(booking.actualEntry ?? booking.startTime),
          ),
          _InfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booking',
            value: booking.bookingNumber,
          ),
        ],
      ),
    );
  }
}

class _GateActivityCard extends StatelessWidget {
  final GateActivityModel activity;

  const _GateActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isApproved = activity.result == 'approved';
    final badgeStatus = isApproved ? 'approved' : 'rejected';

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${activity.eventType.toUpperCase()} scan by ${activity.guardName}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PremiumBadge(
                label: activity.result.toUpperCase(),
                status: badgeStatus,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1.0, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 14),
          if (activity.vehicleNumber.isNotEmpty)
            _InfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: activity.vehicleNumber,
            ),
          if (activity.ownerName.isNotEmpty)
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Owner',
              value: activity.ownerName,
            ),
          if (activity.slotNumber.isNotEmpty)
            _InfoRow(
              icon: Icons.local_parking_outlined,
              label: 'Slot',
              value: activity.slotNumber,
            ),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Scanned At',
            value: _formatDateTime(activity.scannedAt),
          ),
          _InfoRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Payment',
            value: _paymentStatusLabel(activity.paymentStatus),
          ),
          if (activity.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                activity.errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(String value) {
  try {
    final dateTime = DateTime.parse(value).toLocal();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} $hour:$minute';
  } catch (_) {
    return value;
  }
}

String _paymentStatusLabel(String? status) {
  switch (status) {
    case 'captured':
      return 'PAYMENT COMPLETED';
    case 'created':
    case 'unpaid':
    case null:
      return 'PAYMENT PENDING';
    case 'failed':
      return 'PAYMENT FAILED';
    case 'refunded':
      return 'PAYMENT REFUNDED';
    default:
      return status.replaceAll('_', ' ').toUpperCase();
  }
}
