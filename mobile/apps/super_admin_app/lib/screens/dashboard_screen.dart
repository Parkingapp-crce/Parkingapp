import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

import '../cubits/societies_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<SocietiesCubit>();
    cubit.loadDashboard();
    cubit.loadSocieties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Dashboard'),
        actions: [
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
      body: BlocBuilder<SocietiesCubit, SocietiesState>(
        builder: (context, state) {
          if (state.isDashboardLoading && state.dashboardData == null) {
            return const LoadingWidget(message: 'Loading dashboard...');
          }

          if (state.error != null && state.dashboardData == null && state.societies.isEmpty) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: _loadData,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Platform Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDashboardCards(state),
                const SizedBox(height: 24),
                Text(
                  'Recent Societies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildRecentSocieties(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCards(SocietiesState state) {
    final data = state.dashboardData;

    // Extract dashboard data or fallback to computed values from societies
    final totalSocieties = data?['total_societies'] ?? state.societies.length;
    final activeSocieties = data?['active_societies'] ??
        state.societies.where((s) => s.isActive).length;
    final totalBookings = data?['total_bookings'] ?? 0;
    final totalSlots = data?['total_slots'] ??
        state.societies.fold<int>(0, (sum, s) => sum + (s.totalSlots ?? 0));
    final totalRevenue = data?['total_revenue'] ?? '0';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _DashboardCard(
          title: 'Total Societies',
          value: '$totalSocieties',
          icon: Icons.apartment,
          color: AppColors.primary,
        ),
        _DashboardCard(
          title: 'Active Societies',
          value: '$activeSocieties',
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        _DashboardCard(
          title: 'Total Slots',
          value: '$totalSlots',
          icon: Icons.local_parking,
          color: AppColors.warning,
        ),
        _DashboardCard(
          title: 'Total Bookings',
          value: '$totalBookings',
          icon: Icons.book_online,
          color: AppColors.slotOccupied,
        ),
        _DashboardCard(
          title: 'Revenue',
          value: '\u20B9$totalRevenue',
          icon: Icons.currency_rupee,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildRecentSocieties(SocietiesState state) {
    if (state.isLoading && state.societies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: LoadingWidget(),
      );
    }

    if (state.societies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyStateWidget(
            icon: Icons.apartment,
            title: 'No societies yet',
            subtitle: 'Add your first society to get started',
          ),
        ),
      );
    }

    // Show up to 5 recent societies
    final recent = state.societies.take(5).toList();

    return Column(
      children: recent.map((society) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: society.isActive
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.textSecondary.withOpacity(0.1),
              child: Icon(
                Icons.apartment,
                color: society.isActive
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
            title: Text(
              society.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${society.city} | ${society.totalSlots ?? 0} slots',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: society.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                society.isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: society.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
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
