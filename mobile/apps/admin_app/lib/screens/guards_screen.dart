import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/guards_cubit.dart';

class GuardsScreen extends StatefulWidget {
  const GuardsScreen({super.key});

  @override
  State<GuardsScreen> createState() => _GuardsScreenState();
}

class _GuardsScreenState extends State<GuardsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGuards();
  }

  void _loadGuards() {
    context.read<GuardsCubit>().loadGuards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guards'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGuards),
        ],
      ),
      body: BlocConsumer<GuardsCubit, GuardsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.guards.isEmpty) {
            return const LoadingWidget(message: 'Loading guards...');
          }

          return RefreshIndicator(
            onRefresh: () async => _loadGuards(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle(
                  title: 'Pending Approval',
                  subtitle:
                      '${state.pendingGuards.length} guard request(s) waiting for review',
                ),
                const SizedBox(height: 12),
                if (state.pendingGuards.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No pending guard requests.'),
                    ),
                  )
                else
                  ...state.pendingGuards.map(
                    (guard) => _GuardApprovalCard(
                      guard: guard,
                      isSubmitting: state.isSubmitting,
                      onApprove: () =>
                          context.read<GuardsCubit>().approveGuard(guard.id),
                      onReject: () =>
                          context.read<GuardsCubit>().rejectGuard(guard.id),
                    ),
                  ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Approved Guards',
                  subtitle:
                      '${state.approvedGuards.length} approved guard(s) linked to this society',
                ),
                const SizedBox(height: 12),
                if (state.approvedGuards.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No approved guards yet.'),
                    ),
                  )
                else
                  ...state.approvedGuards.map(
                    (guard) => _GuardInfoCard(
                      guard: guard,
                      color: AppColors.success,
                      statusLabel: 'APPROVED',
                    ),
                  ),
                if (state.rejectedGuards.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Rejected Requests',
                    subtitle:
                        '${state.rejectedGuards.length} rejected application(s)',
                  ),
                  const SizedBox(height: 12),
                  ...state.rejectedGuards.map(
                    (guard) => _GuardInfoCard(
                      guard: guard,
                      color: AppColors.error,
                      statusLabel: 'REJECTED',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

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

class _GuardApprovalCard extends StatelessWidget {
  final UserModel guard;
  final bool isSubmitting;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _GuardApprovalCard({
    required this.guard,
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guard.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(guard.email),
            const SizedBox(height: 4),
            Text(guard.phone),
            const SizedBox(height: 4),
            Text('Society: ${guard.societyName ?? '-'}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : onApprove,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onReject,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
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

class _GuardInfoCard extends StatelessWidget {
  final UserModel guard;
  final Color color;
  final String statusLabel;

  const _GuardInfoCard({
    required this.guard,
    required this.color,
    required this.statusLabel,
  });

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
                    guard.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(guard.email),
            const SizedBox(height: 4),
            Text(guard.phone),
            if (guard.approvalNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                guard.approvalNotes,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
