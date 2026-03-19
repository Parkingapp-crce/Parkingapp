import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/societies_cubit.dart';

class SocietyListScreen extends StatefulWidget {
  const SocietyListScreen({super.key});

  @override
  State<SocietyListScreen> createState() => _SocietyListScreenState();
}

class _SocietyListScreenState extends State<SocietyListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SocietiesCubit>().loadSocieties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Societies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SocietiesCubit>().loadSocieties(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/societies/create'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search societies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SocietiesCubit>().search('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<SocietiesCubit>().search(value);
                setState(() {}); // Update suffix icon visibility
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SocietiesCubit, SocietiesState>(
              builder: (context, state) {
                if (state.isLoading && state.societies.isEmpty) {
                  return const LoadingWidget(message: 'Loading societies...');
                }

                if (state.error != null && state.societies.isEmpty) {
                  return AppErrorWidget(
                    message: state.error!,
                    onRetry: () =>
                        context.read<SocietiesCubit>().loadSocieties(),
                  );
                }

                final societies = state.filteredSocieties;

                if (societies.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.apartment,
                    title: 'No societies found',
                    subtitle: 'Add a new society to get started',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<SocietiesCubit>().loadSocieties(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: societies.length,
                    itemBuilder: (context, index) {
                      final society = societies[index];
                      return _SocietyCard(
                        society: society,
                        onTap: () =>
                            context.go('/societies/${society.id}'),
                      );
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
  final VoidCallback onTap;

  const _SocietyCard({
    required this.society,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: society.isActive
              ? AppColors.success.withOpacity(0.1)
              : AppColors.textSecondary.withOpacity(0.1),
          child: Icon(
            Icons.apartment,
            color:
                society.isActive ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        title: Text(
          society.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${society.city}, ${society.state}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.local_parking, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Total: ${society.totalSlots ?? 0}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.check_circle_outline, size: 14, color: AppColors.slotAvailable),
                const SizedBox(width: 4),
                Text(
                  'Available: ${society.availableSlots ?? 0}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
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
              color:
                  society.isActive ? AppColors.success : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
