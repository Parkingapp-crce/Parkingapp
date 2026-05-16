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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _canScanEntry = true;
  bool _canScanExit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GuardsCubit>().loadGuards();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await context.read<GuardsCubit>().createGuard(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        canScanEntry: _canScanEntry,
        canScanExit: _canScanExit,
      );
      _fullNameController.clear();
      _phoneController.clear();
      setState(() {
        _canScanEntry = true;
        _canScanExit = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guard credentials created.')),
      );
    } catch (_) {
      // The bloc listener shows the error.
    }
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
          return RefreshIndicator(
            onRefresh: () async => _loadGuards(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CreateGuardCard(
                  formKey: _formKey,
                  fullNameController: _fullNameController,
                  phoneController: _phoneController,
                  canScanEntry: _canScanEntry,
                  canScanExit: _canScanExit,
                  isSubmitting: state.isSubmitting,
                  onEntryChanged: (value) {
                    setState(() => _canScanEntry = value);
                  },
                  onExitChanged: (value) {
                    setState(() => _canScanExit = value);
                  },
                  onSubmit: _submit,
                ),
                if (state.latestGuard != null &&
                    state.temporaryPassword != null) ...[
                  const SizedBox(height: 16),
                  _CredentialsCard(
                    guard: state.latestGuard!,
                    password: state.temporaryPassword!,
                  ),
                ],
                const SizedBox(height: 24),
                if (state.isLoading && state.guards.isEmpty)
                  const LoadingWidget(message: 'Loading guards...')
                else if (state.error != null && state.guards.isEmpty)
                  AppErrorWidget(message: state.error!, onRetry: _loadGuards)
                else ...[
                  _GuardSection(
                    title: 'Pending Approval',
                    subtitle:
                        '${state.pendingGuards.length} guard request(s) waiting for review',
                    emptyText: 'No pending guard requests.',
                    guards: state.pendingGuards,
                    builder: (guard) => _GuardApprovalCard(
                      guard: guard,
                      isSubmitting: state.isSubmitting,
                      onApprove: () =>
                          context.read<GuardsCubit>().approveGuard(guard.id),
                      onReject: () =>
                          context.read<GuardsCubit>().rejectGuard(guard.id),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GuardSection(
                    title: 'Approved Guards',
                    subtitle:
                        '${state.approvedGuards.length} approved guard(s) linked to this society',
                    emptyText: 'No approved guards yet.',
                    guards: state.approvedGuards,
                    builder: (guard) => _GuardInfoCard(guard: guard),
                  ),
                  if (state.rejectedGuards.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _GuardSection(
                      title: 'Rejected Requests',
                      subtitle:
                          '${state.rejectedGuards.length} rejected application(s)',
                      emptyText: 'No rejected guard requests.',
                      guards: state.rejectedGuards,
                      builder: (guard) => _GuardInfoCard(guard: guard),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CreateGuardCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final bool canScanEntry;
  final bool canScanExit;
  final bool isSubmitting;
  final ValueChanged<bool> onEntryChanged;
  final ValueChanged<bool> onExitChanged;
  final VoidCallback onSubmit;

  const _CreateGuardCard({
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.canScanEntry,
    required this.canScanExit,
    required this.isSubmitting,
    required this.onEntryChanged,
    required this.onExitChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Guard',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: fullNameController,
                label: 'Full Name',
                hint: 'Enter guard name',
                prefixIcon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Guard name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phoneController,
                label: 'Phone',
                hint: 'Enter guard phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: canScanEntry,
                onChanged: onEntryChanged,
                title: const Text('Can scan entry QR codes'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: canScanExit,
                onChanged: onExitChanged,
                title: const Text('Can scan exit QR codes'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Generate Guard Credentials',
                icon: Icons.vpn_key_outlined,
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialsCard extends StatelessWidget {
  final UserModel guard;
  final String password;

  const _CredentialsCard({required this.guard, required this.password});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporary credentials generated',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText('Email: ${guard.email}'),
            const SizedBox(height: 4),
            SelectableText('Temporary Password: $password'),
            const SizedBox(height: 8),
            Text(
              'Share these credentials securely with the guard.',
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

class _GuardSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyText;
  final List<UserModel> guards;
  final Widget Function(UserModel guard) builder;

  const _GuardSection({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.guards,
    required this.builder,
  });

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
        const SizedBox(height: 12),
        if (guards.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyText),
            ),
          )
        else
          ...guards.map(builder),
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
            if (guard.societyName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('Society: ${guard.societyName}'),
            ],
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

  const _GuardInfoCard({required this.guard});

  @override
  Widget build(BuildContext context) {
    final color = _approvalColor(guard.approvalStatus);
    final statusLabel = guard.approvalStatus.replaceAll('_', ' ').toUpperCase();

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
                _StatusChip(label: statusLabel, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(guard.email),
            const SizedBox(height: 4),
            Text(guard.phone),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PermissionChip(label: 'Entry', enabled: guard.canScanEntry),
                _PermissionChip(label: 'Exit', enabled: guard.canScanExit),
              ],
            ),
            if (guard.approvalNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                guard.approvalNotes,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (guard.isApproved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _openPermissionEditor(context),
                  icon: const Icon(Icons.tune),
                  label: const Text('Edit Scan Access'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openPermissionEditor(BuildContext context) async {
    bool canScanEntry = guard.canScanEntry;
    bool canScanExit = guard.canScanExit;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Edit Access: ${guard.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can scan entry QR codes'),
                    value: canScanEntry,
                    onChanged: (value) {
                      setState(() => canScanEntry = value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can scan exit QR codes'),
                    value: canScanExit,
                    onChanged: (value) {
                      setState(() => canScanExit = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!canScanEntry && !canScanExit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enable at least one scan permission.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) return;

    try {
      await context.read<GuardsCubit>().updateGuardPermissions(
        guardId: guard.id,
        canScanEntry: canScanEntry,
        canScanExit: canScanExit,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guard scan access updated.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update scan access.')),
      );
    }
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _PermissionChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.error;
    return _StatusChip(
      label: '$label: ${enabled ? 'Allowed' : 'Blocked'}',
      color: color,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _approvalColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.success;
    case 'pending':
      return AppColors.warning;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}
