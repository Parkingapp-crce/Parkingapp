import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final cubit = context.read<GuardsCubit>();
        cubit.loadGuards();
        cubit.loadSavedGuardCredentials();
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
      final result = await context.read<GuardsCubit>().createGuard(
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            canScanEntry: _canScanEntry,
            canScanExit: _canScanExit,
          );

      if (result != null && mounted) {
        await _showCredentialsDialog(
          result['device'] as UserModel,
          result['password'] as String,
        );
      }

      _fullNameController.clear();
      _phoneController.clear();
      setState(() {
        _canScanEntry = true;
        _canScanExit = true;
      });
    } catch (_) {
      // Error handled by listener.
    }
  }

  Future<void> _showCredentialsDialog(UserModel device, String password) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Guard Credentials'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Credentials generated successfully for this gate device:'),
            const SizedBox(height: 16),
            _CredentialField(label: 'Email', value: device.email),
            const SizedBox(height: 12),
            _CredentialField(label: 'Password', value: password),
            const SizedBox(height: 16),
            Text(
              'Share these credentials securely with the gate operator or device setup team.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPermissionEditor(UserModel guard) async {
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
                    onChanged: (value) => setState(() => canScanEntry = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Can scan exit QR codes'),
                    value: canScanExit,
                    onChanged: (value) => setState(() => canScanExit = value),
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

    if (saved != true || !mounted) return;

    try {
      await context.read<GuardsCubit>().updateGuardPermissions(
            guardId: guard.id,
            canScanEntry: canScanEntry,
            canScanExit: canScanExit,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guard scan access updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update scan access.')),
      );
    }
  }

  Future<void> _confirmDelete(UserModel guard) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device?'),
        content: Text(
          'This will deactivate ${guard.fullName} and remove access for this device. You can create fresh credentials later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await context.read<GuardsCubit>().deleteGuard(guard.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device deactivated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete device.')),
      );
    }
  }

  Future<void> _copyText({required String label, required String text}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }

  Future<void> _showGuardCredentialsDialog(UserModel guard) async {
    final password = guard.temporaryPassword;
    if (password == null || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credentials available for this guard.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Guard Credentials'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${guard.fullName}'),
            const SizedBox(height: 8),
            _CredentialField(label: 'Email', value: guard.email),
            const SizedBox(height: 12),
            _CredentialField(label: 'Password', value: password),
            const SizedBox(height: 16),
            Text(
              'These credentials belong to the selected guard card. Copy them now or later from this same card.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _copyText(
              label: 'Credentials',
              text: _buildShareText(email: guard.email, password: password),
            ),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy Credentials'),
          ),
        ],
      ),
    );
  }

  String _buildShareText({required String email, required String password}) {
    return '''Guard credentials\n\nEmail: $email\nPassword: $password\n\nUse these credentials on the assigned gate device only. If the device changes, regenerate credentials from the admin app.''';
  }

  void _loadGuards() {
    context.read<GuardsCubit>().loadGuards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Devices'),
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
                backgroundColor: Theme.of(context).colorScheme.error,
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
                  onEntryChanged: (value) => setState(() => _canScanEntry = value),
                  onExitChanged: (value) => setState(() => _canScanExit = value),
                  onSubmit: _submit,
                ),
                const SizedBox(height: 24),
                if (state.isLoading && state.guards.isEmpty)
                  const LoadingWidget(message: 'Loading guards...')
                else if (state.error != null && state.guards.isEmpty)
                  AppErrorWidget(message: state.error!, onRetry: _loadGuards)
                else ...[
                  _GuardSection(
                    title: 'Pending Approval',
                    subtitle:
                        '${state.pendingGuards.length} gate request(s) waiting for review',
                    emptyText: 'No pending gate requests.',
                    guards: state.pendingGuards,
                    builder: (guard) => _GuardApprovalCard(
                      guard: guard,
                      isSubmitting: state.isSubmitting,
                      onViewCredentials: guard.temporaryPassword != null &&
                          guard.temporaryPassword!.isNotEmpty
                        ? () => _showGuardCredentialsDialog(guard)
                        : null,
                      onApprove: () =>
                          context.read<GuardsCubit>().approveGuard(guard.id),
                      onReject: () =>
                          context.read<GuardsCubit>().rejectGuard(guard.id),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GuardSection(
                    title: 'Approved Gate Devices',
                    subtitle:
                        '${state.approvedGuards.length} approved gate device(s) linked to this society',
                    emptyText: 'No approved gate devices yet.',
                    guards: state.approvedGuards,
                    builder: (guard) => _GuardInfoCard(
                      guard: guard,
                      onViewCredentials: guard.temporaryPassword != null &&
                              guard.temporaryPassword!.isNotEmpty
                          ? () => _showGuardCredentialsDialog(guard)
                          : null,
                      onEdit: () => _openPermissionEditor(guard),
                      onDelete: () => _confirmDelete(guard),
                    ),
                  ),
                  if (state.rejectedGuards.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _GuardSection(
                      title: 'Rejected Requests',
                      subtitle:
                          '${state.rejectedGuards.length} rejected application(s)',
                      emptyText: 'No rejected gate requests.',
                      guards: state.rejectedGuards,
                      builder: (guard) => _GuardInfoCard(
                        guard: guard,
                        onViewCredentials: guard.temporaryPassword != null &&
                                guard.temporaryPassword!.isNotEmpty
                            ? () => _showGuardCredentialsDialog(guard)
                            : null,
                        onEdit: () => _openPermissionEditor(guard),
                        onDelete: () => _confirmDelete(guard),
                      ),
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
                'Create New Gate Device',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: fullNameController,
                label: 'Device Name',
                hint: 'Enter gate device name',
                prefixIcon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Device name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phoneController,
                label: 'Device ID',
                hint: 'Enter gate device ID',
                prefixIcon: Icons.qr_code_scanner_outlined,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Device ID is required';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 3) {
                    return 'Enter a valid device ID (min 3 chars)';
                  }
                  if (trimmed.length > 15) {
                    return 'Device ID cannot exceed 15 characters';
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
                label: 'Generate Gate Credentials',
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
  final VoidCallback? onViewCredentials;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _GuardApprovalCard({
    required this.guard,
    required this.isSubmitting,
    required this.onViewCredentials,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(guard.email),
            const SizedBox(height: 4),
            Text(guard.phone),
            if (guard.societyName != null && guard.societyName!.isNotEmpty) ...[
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
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
            if (onViewCredentials != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewCredentials,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('View Credentials'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuardInfoCard extends StatelessWidget {
  final UserModel guard;
  final VoidCallback? onViewCredentials;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuardInfoCard({
    required this.guard,
    required this.onViewCredentials,
    required this.onEdit,
    required this.onDelete,
  });

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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (onViewCredentials != null)
                  OutlinedButton.icon(
                    onPressed: onViewCredentials,
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('View Credentials'),
                  ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune),
                  label: const Text('Edit Scan Access'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
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

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _PermissionChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : const Color(0xFFEF4444);
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
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF64748B);
  }
}

class _CredentialField extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(child: SelectableText(value)),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied to clipboard.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}