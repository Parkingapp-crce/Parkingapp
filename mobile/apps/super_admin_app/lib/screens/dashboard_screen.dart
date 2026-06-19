import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
    context.read<SocietiesCubit>().startDashboardPolling();
  }

  void _loadData() {
    final cubit = context.read<SocietiesCubit>();
    cubit.loadDashboard();
    cubit.loadSocieties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SocietiesCubit, SocietiesState>(
          builder: (context, state) {
            if (state.isDashboardLoading && state.dashboardData == null) {
              return const LoadingWidget(message: 'Loading dashboard...');
            }

            if (state.error != null &&
                state.dashboardData == null &&
                state.societies.isEmpty) {
              return AppErrorWidget(
                  message: state.error!, onRetry: _loadData);
            }

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.tertiary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              onRefresh: () async => _loadData(),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                children: [
                  // ── Top Bar ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SYSTEM OVERVIEW',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Platform Control Center',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _BarAction(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Refresh',
                          onPressed: _loadData,
                        ),
                        const SizedBox(width: 4),
                        ListenableBuilder(
                          listenable: GetIt.I<ThemeNotifier>(),
                          builder: (context, _) {
                            final isDark = GetIt.I<ThemeNotifier>().isDark;
                            return _BarAction(
                              icon: isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              tooltip: isDark ? 'Light mode' : 'Dark mode',
                              onPressed: GetIt.I<ThemeNotifier>().toggle,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _BarAction(
                          icon: Icons.logout_rounded,
                          tooltip: 'Sign out',
                          onPressed: () =>
                              context.read<AuthBloc>().add(const AuthLoggedOut()),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 24),

                  // ── Onboard Society action ───────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go('/societies/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: Theme.of(context).colorScheme.onSurface, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'ONBOARD NEW SOCIETY',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Metric Tiles ─────────────────────────────────────────────
                  _buildMetricGrid(state),
                  const SizedBox(height: 28),

                  // ── Societies list ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SOCIETIES',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          fontFamily: 'Inter',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/societies'),
                        child: Text(
                          'View all →',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSocietiesList(state),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricGrid(SocietiesState state) {
    final data = state.dashboardData;
    final totalSocieties =
        data?['total_societies'] ?? state.societies.length;
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
        PremiumMetricTile(
          label: 'Total Societies',
          value: '$totalSocieties',
          icon: Icons.apartment_rounded,
        ),
        PremiumMetricTile(
          label: 'Active Societies',
          value: '$activeSocieties',
          icon: Icons.check_circle_outline_rounded,
          valueColor: AppColors.success,
        ),
        PremiumMetricTile(
          label: 'Total Slots',
          value: '$totalSlots',
          icon: Icons.local_parking_rounded,
        ),
        PremiumMetricTile(
          label: 'Total Bookings',
          value: '$totalBookings',
          icon: Icons.receipt_long_rounded,
        ),
        PremiumMetricTile(
          label: 'Platform Revenue',
          value: '₹$totalRevenue',
          icon: Icons.payments_rounded,
          valueColor: AppColors.tertiary,
        ),
      ],
    );
  }

  Widget _buildSocietiesList(SocietiesState state) {
    if (state.isLoading && state.societies.isEmpty) {
      return const Padding(padding: EdgeInsets.all(32), child: LoadingWidget());
    }

    if (state.societies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: const EmptyStateWidget(
          icon: Icons.apartment_outlined,
          title: 'No societies yet',
          subtitle: 'Add your first society to get started',
        ),
      );
    }

    final recent = state.societies.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'SOCIETY',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Text(
                  'STATUS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...recent.mapIndexed((i, society) => _SocietyRow(
                society: society,
                isLast: i == recent.length - 1,
              )),
        ],
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
      ),
    );
  }
}

class _SocietyRow extends StatelessWidget {
  final dynamic society;
  final bool isLast;

  const _SocietyRow({required this.society, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/societies/${society.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${society.totalSlots ?? 0} slots',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                society.city.isNotEmpty ? society.city : '—',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: society.isActive
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  society.isActive ? 'LIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: society.isActive
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _Indexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}
