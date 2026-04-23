import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guard credentials created.')),
        );
      }
    } catch (_) {
      // State listener handles the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuardsCubit, GuardsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Guard Credentials'),
            actions: [
              IconButton(
                onPressed: () => context.read<GuardsCubit>().loadGuards(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Generate guard access for your society',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guard email and temporary password are created by the admin panel. You decide whether the guard can scan entry, exit, or both.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                if (state.latestGuard != null && state.temporaryPassword != null)
                  _CredentialsCard(
                    guard: state.latestGuard!,
                    password: state.temporaryPassword!,
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create New Guard',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _fullNameController,
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
                            controller: _phoneController,
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
                            value: _canScanEntry,
                            onChanged: (value) {
                              setState(() => _canScanEntry = value);
                            },
                            title: const Text('Can scan entry QR codes'),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _canScanExit,
                            onChanged: (value) {
                              setState(() => _canScanExit = value);
                            },
                            title: const Text('Can scan exit QR codes'),
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<GuardsCubit, GuardsState>(
                            builder: (context, state) {
                              return PrimaryButton(
                                label: 'Generate Guard Credentials',
                                icon: Icons.vpn_key_outlined,
                                isLoading: state.isSubmitting,
                                onPressed: _submit,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Existing Guards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (state.isLoading && state.guards.isEmpty)
                  const LoadingWidget(message: 'Loading guards...')
                else if (state.error != null && state.guards.isEmpty)
                  AppErrorWidget(
                    message: state.error!,
                    onRetry: () => context.read<GuardsCubit>().loadGuards(),
                  )
                else if (state.guards.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.security_outlined,
                    title: 'No guards yet',
                    subtitle: 'Create the first guard credential from this screen.',
                  )
                else
                  ...state.guards.map((guard) => _GuardCard(guard: guard)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CredentialsCard extends StatelessWidget {
  final GuardCredentialRecord guard;
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText('Email: ${guard.email}'),
            const SizedBox(height: 4),
            SelectableText('Temporary Password: $password'),
            const SizedBox(height: 8),
            Text(
              'Share these credentials securely with the guard.',
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

class _GuardCard extends StatelessWidget {
  final GuardCredentialRecord guard;

  const _GuardCard({required this.guard});

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
            const SizedBox(height: 4),
            Text('${guard.email} • ${guard.phone}'),
            const SizedBox(height: 4),
            Text(
              guard.societyName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  context,
                  label: 'Entry',
                  enabled: guard.canScanEntry,
                ),
                _statusChip(
                  context,
                  label: 'Exit',
                  enabled: guard.canScanExit,
                ),
              ],
            ),
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

    if (saved != true || !context.mounted) {
      return;
    }

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

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${enabled ? 'Allowed' : 'Blocked'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}