import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class OwnerDetailScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;

  const OwnerDetailScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
  });

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  bool _isLoading = true;
  String? _error;
  List<SlotModel> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadOwnerSlots();
  }

  String? get _societyId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  Future<void> _loadOwnerSlots() async {
    final societyId = _societyId;
    if (societyId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiClient>().get(
        ApiEndpoints.societySlots(societyId),
        queryParameters: {'owner_id': widget.ownerId},
      );
      final data = response.data;
      final List<SlotModel> slots = [];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        slots.addAll(
          (data['results'] as List).map(
            (item) => SlotModel.fromJson(item as Map<String, dynamic>),
          ),
        );
      } else if (data is List) {
        slots.addAll(
          data.map((item) => SlotModel.fromJson(item as Map<String, dynamic>)),
        );
      }

      setState(() {
        _isLoading = false;
        _slots = slots;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'R';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.ownerName)),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading owner details...')
          : _error != null && _slots.isEmpty
          ? AppErrorWidget(message: _error!, onRetry: _loadOwnerSlots)
          : RefreshIndicator(
              onRefresh: _loadOwnerSlots,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Profile Detail Card ────────────────────────────────
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceBright,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      _getInitials(widget.ownerName),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.ownerName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppColors.success.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            'APPROVED',
                                            style: textTheme.bodySmall?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                              const SizedBox(height: 16),
                              _DetailRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: widget.ownerEmail,
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: widget.ownerPhone,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Owner Slots',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_slots.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.local_parking,
                          title: 'No slots found',
                          subtitle: 'This owner has not added any slots yet.',
                        )
                      else
                        ..._slots.map(
                          (slot) {
                            final slotColor = slot.approvalStatus == 'approved'
                                ? AppColors.success
                                : slot.approvalStatus == 'rejected'
                                ? Theme.of(context).colorScheme.error
                                : AppColors.warning;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceBright,
                              child: ListTile(
                                onTap: () => context.push('/slots/${slot.id}'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: slotColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      slot.slotType == 'bike'
                                          ? Icons.two_wheeler_rounded
                                          : Icons.directions_car_rounded,
                                      color: slotColor,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Slot ${slot.slotNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Type: ${slot.slotType.toUpperCase()} | Rate: \u20B9${slot.hourlyRate}/hr',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Status: ${slot.approvalStatus.toUpperCase()}',
                                        style: TextStyle(
                                          color: slotColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
