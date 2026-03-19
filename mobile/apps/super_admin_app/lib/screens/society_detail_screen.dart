import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/societies_cubit.dart';

class SocietyDetailScreen extends StatefulWidget {
  final String societyId;

  const SocietyDetailScreen({super.key, required this.societyId});

  @override
  State<SocietyDetailScreen> createState() => _SocietyDetailScreenState();
}

class _SocietyDetailScreenState extends State<SocietyDetailScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final cubit = context.read<SocietiesCubit>();
      final stats = await cubit.loadSocietyStats(widget.societyId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocietiesCubit, SocietiesState>(
      builder: (context, state) {
        final society =
            context.read<SocietiesCubit>().getSocietyById(widget.societyId);

        if (society == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Society Details')),
            body: const AppErrorWidget(message: 'Society not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(society.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.go('/societies/${widget.societyId}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: society.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: society.isActive
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 48,
                      color: society.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            society.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            society.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: society.isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Slot summary
              _buildSlotSummary(society),
              const SizedBox(height: 16),

              // Stats from API
              if (_isLoadingStats)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: LoadingWidget(message: 'Loading stats...'),
                  ),
                )
              else if (_stats != null)
                _buildStatsCard(),

              const SizedBox(height: 16),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Society Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Divider(height: 24),
                      _DetailRow(label: 'Name', value: society.name),
                      _DetailRow(label: 'Address', value: society.address),
                      _DetailRow(label: 'City', value: society.city),
                      _DetailRow(label: 'State', value: society.state),
                      _DetailRow(label: 'Pincode', value: society.pincode),
                      _DetailRow(
                          label: 'Contact Email', value: society.contactEmail),
                      _DetailRow(
                          label: 'Contact Phone', value: society.contactPhone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle active/inactive
              SizedBox(
                width: double.infinity,
                height: 48,
                child: society.isActive
                    ? OutlinedButton.icon(
                        onPressed: () => _toggleActive(society),
                        icon: const Icon(Icons.pause_circle_outline,
                            color: AppColors.error),
                        label: const Text(
                          'Deactivate Society',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                        ),
                      )
                    : PrimaryButton(
                        label: 'Activate Society',
                        icon: Icons.play_circle_outline,
                        onPressed: () => _toggleActive(society),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlotSummary(SocietyModel society) {
    final total = society.totalSlots ?? 0;
    final available = society.availableSlots ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total Slots',
                    value: '$total',
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Available',
                    value: '$available',
                    color: AppColors.slotAvailable,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'In Use',
                    value: '${total - available}',
                    color: AppColors.slotOccupied,
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? (total - available) / total : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            if (_stats!['total_bookings'] != null)
              _DetailRow(
                label: 'Total Bookings',
                value: '${_stats!['total_bookings']}',
              ),
            if (_stats!['active_bookings'] != null)
              _DetailRow(
                label: 'Active Bookings',
                value: '${_stats!['active_bookings']}',
              ),
            if (_stats!['total_revenue'] != null)
              _DetailRow(
                label: 'Total Revenue',
                value: '\u20B9${_stats!['total_revenue']}',
              ),
            if (_stats!['occupancy_rate'] != null)
              _DetailRow(
                label: 'Occupancy Rate',
                value: '${_stats!['occupancy_rate']}%',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(SocietyModel society) async {
    final newStatus = !society.isActive;
    final action = newStatus ? 'activate' : 'deactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Society'),
        content: Text(
          'Are you sure you want to $action ${society.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? AppColors.success : AppColors.error,
            ),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<SocietiesCubit>().toggleSocietyActive(
            widget.societyId,
            newStatus,
          );
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
