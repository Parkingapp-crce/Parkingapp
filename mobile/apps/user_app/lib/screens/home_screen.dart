import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/societies_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SocietiesCubit(GetIt.instance<ApiClient>())..loadSocieties(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkEase'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                context.read<SocietiesCubit>().search(value);
              },
              decoration: InputDecoration(
                hintText: 'Search societies...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SocietiesCubit, SocietiesState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const LoadingWidget(message: 'Loading societies...');
                }

                if (state.error != null) {
                  return AppErrorWidget(
                    message: state.error!,
                    onRetry: () =>
                        context.read<SocietiesCubit>().loadSocieties(),
                  );
                }

                final societies = state.filteredSocieties;

                if (societies.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.location_city_outlined,
                    title: 'No societies found',
                    subtitle: 'Try adjusting your search query',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<SocietiesCubit>().loadSocieties(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: societies.length,
                    itemBuilder: (context, index) {
                      return _SocietyCard(society: societies[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocietyCard extends StatelessWidget {
  final SocietyModel society;

  const _SocietyCard({required this.society});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/societies/${society.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          society.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${society.address}, ${society.city}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SlotBadge(
                    label: 'Total',
                    count: society.totalSlots ?? 0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  _SlotBadge(
                    label: 'Available',
                    count: society.availableSlots ?? 0,
                    color: AppColors.success,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SlotBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
