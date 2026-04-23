import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/slots_cubit.dart';

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
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.user.society != null) {
      final societyId = authState.user.society!;
      context.read<SlotsCubit>().loadSlots(societyId);
      _loadJoinCode(societyId);
    }
  }

  Future<void> _loadJoinCode(String societyId) async {
    setState(() {
      _isJoinCodeLoading = true;
    });
    try {
      final response = await context.read<ApiClient>().get(ApiEndpoints.society(societyId));
      final data = response.data;
      if (!mounted) return;
      if (data is Map<String, dynamic>) {
        setState(() {
          _joinCode = data['join_code'] as String?;
          _isJoinCodeLoading = false;
        });
      } else {
        setState(() {
          _joinCode = null;
          _isJoinCodeLoading = false;
        });
      }
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLoggedOut());
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const LoadingWidget(message: 'Loading...');
          }

          if (authState.user.society == null) {
            return const AppErrorWidget(
              message: 'No society assigned to this admin account.',
            );
          }

          return BlocBuilder<SlotsCubit, SlotsState>(
            builder: (context, slotsState) {
              if (slotsState.isLoading && slotsState.slots.isEmpty) {
                return const LoadingWidget(message: 'Loading dashboard...');
              }

              if (slotsState.error != null && slotsState.slots.isEmpty) {
                return AppErrorWidget(
                  message: slotsState.error!,
                  onRetry: _loadData,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Parking Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
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
                                    _isJoinCodeLoading
                                        ? 'Loading...'
                                        : (_joinCode?.isNotEmpty == true ? _joinCode! : 'Unavailable'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy code',
                              onPressed: (_joinCode?.isNotEmpty == true)
                                  ? () async {
                                      await Clipboard.setData(ClipboardData(text: _joinCode!));
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Join code copied')),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.how_to_reg, color: AppColors.primary),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Review new resident join requests before they can access parking flows.',
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => context.go('/join-requests'),
                                child: const Text('Join Requests'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: AppColors.primary),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Generate guard credentials and control who can scan entry or exit QR codes.',
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => context.go('/guards'),
                                child: const Text('Manage Guards'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    _buildSummaryGrid(slotsState),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildOccupancyCard(slotsState),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(SlotsState slotsState) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(
          title: 'Total Slots',
          count: slotsState.totalCount,
          icon: Icons.local_parking,
          color: AppColors.primary,
        ),
        _SummaryCard(
          title: 'Available',
          count: slotsState.availableCount,
          icon: Icons.check_circle_outline,
          color: AppColors.slotAvailable,
        ),
        _SummaryCard(
          title: 'Reserved',
          count: slotsState.reservedCount,
          icon: Icons.schedule,
          color: AppColors.slotReserved,
        ),
        _SummaryCard(
          title: 'Occupied',
          count: slotsState.occupiedCount,
          icon: Icons.directions_car,
          color: AppColors.slotOccupied,
        ),
        _SummaryCard(
          title: 'Blocked',
          count: slotsState.blockedCount,
          icon: Icons.block,
          color: AppColors.slotBlocked,
        ),
      ],
    );
  }

  Widget _buildOccupancyCard(SlotsState slotsState) {
    final total = slotsState.totalCount;
    final occupied = slotsState.occupiedCount + slotsState.reservedCount;
    final occupancyRate = total > 0 ? (occupied / total * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Occupancy Rate',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${occupancyRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? occupied / total : 0,
                minHeight: 10,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  occupancyRate > 80
                      ? AppColors.error
                      : occupancyRate > 50
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$occupied of $total slots in use',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
