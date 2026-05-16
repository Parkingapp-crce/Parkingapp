import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    context.read<DashboardCubit>().startPolling();
  }

  void _loadData() {
    context.read<DashboardCubit>().loadDashboard();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.user.society != null) {
      _loadJoinCode(authState.user.society!);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLoggedOut());
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
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
              padding: const EdgeInsets.all(16),
              children: [
                _AdminActionsCard(
                  joinCode: _joinCode,
                  isJoinCodeLoading: _isJoinCodeLoading,
                ),
                const SizedBox(height: 16),
                Text(
                  'Today at a glance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _SummaryGrid(dashboard: dashboard),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Society Join Code',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayCode,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
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
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  icon: Icons.how_to_reg,
                  label: 'Join Requests',
                  onPressed: () => context.go('/join-requests'),
                ),
                _ActionButton(
                  icon: Icons.security,
                  label: 'Manage Guards',
                  onPressed: () => context.go('/guards'),
                ),
                _ActionButton(
                  icon: Icons.people_alt,
                  label: 'Owners',
                  onPressed: () => context.go('/owners'),
                ),
              ],
            ),
          ],
        ),
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
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final AdminDashboardModel dashboard;

  const _SummaryGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        title: 'Total Slots',
        value: dashboard.totalSlots.toString(),
        icon: Icons.local_parking,
        color: AppColors.primary,
      ),
      _SummaryItem(
        title: 'Occupied',
        value: dashboard.occupiedSlots.toString(),
        icon: Icons.directions_car,
        color: AppColors.slotOccupied,
      ),
      _SummaryItem(
        title: 'Reserved',
        value: dashboard.reservedSlots.toString(),
        icon: Icons.schedule,
        color: AppColors.slotReserved,
      ),
      _SummaryItem(
        title: 'Active Bookings',
        value: dashboard.activeBookings.toString(),
        icon: Icons.book_online,
        color: AppColors.success,
      ),
      _SummaryItem(
        title: 'Guard Requests',
        value: dashboard.pendingGuardRequests.toString(),
        icon: Icons.security,
        color: AppColors.warning,
      ),
      _SummaryItem(
        title: 'Completed Today',
        value: dashboard.completedToday.toString(),
        icon: Icons.task_alt,
        color: AppColors.textSecondary,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _SummaryCard(item: items[index]),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            Text(
              item.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

class _ParkedVehicleCard extends StatelessWidget {
  final BookingModel booking;

  const _ParkedVehicleCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.vehicle?.registrationNo ?? 'Unknown vehicle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(
                  label: booking.paymentStatusLabel,
                  color: _paymentStatusColor(booking.paymentStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline,
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
              icon: Icons.login,
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
    final badgeColor = isApproved ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${activity.eventType.toUpperCase()} scan by ${activity.guardName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(
                  label: activity.result.toUpperCase(),
                  color: badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (activity.vehicleNumber.isNotEmpty)
              _InfoRow(
                icon: Icons.directions_car_outlined,
                label: 'Vehicle',
                value: activity.vehicleNumber,
              ),
            if (activity.ownerName.isNotEmpty)
              _InfoRow(
                icon: Icons.person_outline,
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
              icon: Icons.access_time,
              label: 'Scanned At',
              value: _formatDateTime(activity.scannedAt),
            ),
            _InfoRow(
              icon: Icons.currency_rupee,
              label: 'Payment',
              value: _paymentStatusLabel(activity.paymentStatus),
            ),
            if (activity.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  activity.errorMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
          Icon(icon, size: 16, color: AppColors.textSecondary),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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

Color _paymentStatusColor(String? status) {
  switch (status) {
    case 'captured':
      return AppColors.success;
    case 'created':
    case 'unpaid':
      return AppColors.warning;
    case 'failed':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
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
