import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

import '../cubits/refund_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight date formatter (avoids adding the intl package)
// ─────────────────────────────────────────────────────────────────────────────
String _formatDateTime(DateTime d) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} '
      '${d.year.toString().substring(2)}, $h:$m $ampm';
}

// ─────────────────────────────────────────────────────────────────────────────
// Root screen with tab switcher
// ─────────────────────────────────────────────────────────────────────────────
class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<RefundCubit>().loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYMENT OPERATIONS',
                          style: TextStyle(
                            color: cs.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Refund & Rollback',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded,
                            color: AppColors.error, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'SUPER ADMIN',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
                height: 1, color: cs.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 20)),
            // ── Tabs ─────────────────────────────────────────────────────────
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: cs.onPrimary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
                tabs: const [
                  Tab(text: 'Issue Refund'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            // ── Tab views ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _IssueRefundTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 – Issue Refund
// ─────────────────────────────────────────────────────────────────────────────
class _IssueRefundTab extends StatefulWidget {
  const _IssueRefundTab();

  @override
  State<_IssueRefundTab> createState() => _IssueRefundTabState();
}

class _IssueRefundTabState extends State<_IssueRefundTab> {
  final _bookingIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  bool _isFullRefund = true;

  @override
  void dispose() {
    _bookingIdCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _lookup() {
    FocusScope.of(context).unfocus();
    context.read<RefundCubit>().lookupBooking(_bookingIdCtrl.text.trim());
  }

  void _onFullRefundToggle(bool full, Map<String, dynamic> data) {
    setState(() => _isFullRefund = full);
    if (full) {
      final max = _parseDecimal(data['max_refundable']);
      _amountCtrl.text = max?.toStringAsFixed(2) ?? '';
    }
  }

  double? _parseDecimal(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  Future<void> _submit(Map<String, dynamic> data) async {
    final bookingId = data['booking_id']?.toString() ?? '';
    final maxRefundable = _parseDecimal(data['max_refundable']) ?? 0;
    final alreadyRefunded = _parseDecimal(data['already_refunded']) ?? 0;
    final actualMax = maxRefundable - alreadyRefunded;

    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid refund amount.');
      return;
    }
    if (amount > actualMax + 0.001) {
      _showError(
          'Amount ₹${amount.toStringAsFixed(2)} exceeds max refundable ₹${actualMax.toStringAsFixed(2)}.');
      return;
    }
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      _showError('Please provide a reason for the refund.');
      return;
    }

    // Double-confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        bookingNumber: data['booking_number']?.toString() ?? '',
        userName: data['user_name']?.toString() ?? '',
        amount: amount,
        reason: reason,
        isFullRefund: _isFullRefund,
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<RefundCubit>().initiateRefund(
          bookingId: bookingId,
          refundAmount: amount,
          reason: reason,
        );

    if (!mounted) return;
    if (ok) {
      _amountCtrl.clear();
      _reasonCtrl.clear();
      _bookingIdCtrl.clear();
      setState(() => _isFullRefund = true);
      _showSuccess('Refund of ₹${amount.toStringAsFixed(2)} issued successfully.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RefundCubit, RefundState>(
      listener: (ctx, state) {
        // When lookup succeeds, pre-fill amount with full refundable
        if (state.lookupData != null && !state.isLookingUp) {
          final max = _parseDecimal(state.lookupData!['max_refundable']);
          final already = _parseDecimal(state.lookupData!['already_refunded']) ?? 0;
          if (max != null) {
            final net = max - already;
            if (_isFullRefund) {
              _amountCtrl.text = net.toStringAsFixed(2);
            }
          }
        }
      },
      builder: (ctx, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // ── Lookup card ─────────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                      icon: Icons.search_rounded, label: 'LOOKUP BOOKING'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bookingIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Booking ID (UUID)',
                            hintText: 'e.g. 3fa85f64-5717-4562-b3fc-2c963f66afa6',
                          ),
                          onFieldSubmitted: (_) => _lookup(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _LookupButton(
                        isLoading: state.isLookingUp,
                        onTap: _lookup,
                      ),
                    ],
                  ),
                  if (state.lookupError != null) ...[
                    const SizedBox(height: 10),
                    _InlineError(message: state.lookupError!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Booking snapshot ─────────────────────────────────────────────
            if (state.lookupData != null) ...[
              _BookingSnapshotCard(
                data: state.lookupData!,
                onClear: () {
                  context.read<RefundCubit>().clearLookup();
                  _amountCtrl.clear();
                  _reasonCtrl.clear();
                  setState(() => _isFullRefund = true);
                },
              ),
              const SizedBox(height: 14),

              // ── Refund form ────────────────────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                        icon: Icons.currency_rupee_rounded,
                        label: 'REFUND DETAILS'),
                    const SizedBox(height: 14),

                    // Full / Partial toggle
                    _RefundTypeToggle(
                      isFullRefund: _isFullRefund,
                      onChanged: (v) =>
                          _onFullRefundToggle(v, state.lookupData!),
                    ),
                    const SizedBox(height: 14),

                    // Amount field
                    _AmountField(
                      controller: _amountCtrl,
                      focusNode: _amountFocusNode,
                      enabled: !_isFullRefund,
                      maxRefundable: () {
                        final max = _parseDecimal(
                                state.lookupData!['max_refundable']) ??
                            0;
                        final already = _parseDecimal(
                                state.lookupData!['already_refunded']) ??
                            0;
                        return max - already;
                      }(),
                    ),
                    const SizedBox(height: 12),

                    // Reason
                    AppTextField(
                      controller: _reasonCtrl,
                      label: 'Reason *',
                      hint: 'e.g. Customer requested refund via email',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: _SubmitButton(
                        isSubmitting: state.isSubmitting,
                        submitError: state.submitError,
                        onPressed: () => _submit(state.lookupData!),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Empty state hint
              _EmptyLookupHint(),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 – Refund History
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefundCubit, RefundState>(
      builder: (context, state) {
        if (state.isLoadingHistory && state.history.isEmpty) {
          return const Center(child: LoadingWidget(message: 'Loading history…'));
        }
        if (state.historyError != null && state.history.isEmpty) {
          return Center(
            child: AppErrorWidget(
              message: state.historyError!,
              onRetry: () => context.read<RefundCubit>().loadHistory(),
            ),
          );
        }
        if (state.history.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No refunds yet',
              subtitle: 'Issued refunds will appear here',
            ),
          );
        }
        return RefreshIndicator(
          color: Theme.of(context).colorScheme.tertiary,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onRefresh: () => context.read<RefundCubit>().loadHistory(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: state.history.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _RefundHistoryTile(data: state.history[i] as Map<String, dynamic>),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _LookupButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LookupButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: cs.onPrimary, strokeWidth: 2),
              )
            : Icon(Icons.search_rounded, color: cs.onPrimary, size: 20),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSnapshotCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClear;
  const _BookingSnapshotCard({required this.data, required this.onClear});

  String _fmt(dynamic dt) {
    if (dt == null) return '—';
    try {
      return _formatDateTime(DateTime.parse(dt.toString()).toLocal());
    } catch (_) {
      return dt.toString();
    }
  }

  Color _statusColor(String? s) {
    if (s == null) return AppColors.textDisabled;
    if (s.contains('cancelled') || s.contains('failed')) return AppColors.error;
    if (s.contains('confirmed') || s.contains('active') || s.contains('completed')) {
      return AppColors.success;
    }
    if (s.contains('partial')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxRefundable = double.tryParse(data['max_refundable']?.toString() ?? '0') ?? 0;
    final alreadyRefunded = double.tryParse(data['already_refunded']?.toString() ?? '0') ?? 0;
    final netRefundable = maxRefundable - alreadyRefunded;
    final bookingStatus = data['booking_status']?.toString() ?? '';
    final paymentProvider = data['payment_provider']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.07),
            cs.surfaceContainerHighest,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Booking #${data['booking_number'] ?? '—'}',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: cs.onSurfaceVariant, size: 14),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User info
                _SnapshotRow(
                  icon: Icons.person_rounded,
                  label: 'Customer',
                  value:
                      '${data['user_name'] ?? '—'}  •  ${data['user_email'] ?? '—'}',
                ),
                const SizedBox(height: 8),
                _SnapshotRow(
                  icon: Icons.local_parking_rounded,
                  label: 'Slot / Society',
                  value:
                      '${data['slot_number'] ?? '—'} at ${data['society_name'] ?? '—'}',
                ),
                const SizedBox(height: 8),
                _SnapshotRow(
                  icon: Icons.schedule_rounded,
                  label: 'Period',
                  value: '${_fmt(data['start_time'])} → ${_fmt(data['end_time'])}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SnapshotRow(
                        icon: Icons.flag_rounded,
                        label: 'Booking Status',
                        value: bookingStatus,
                        valueColor: _statusColor(bookingStatus),
                      ),
                    ),
                    Expanded(
                      child: _SnapshotRow(
                        icon: Icons.payment_rounded,
                        label: 'Provider',
                        value: paymentProvider.toUpperCase(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Amount summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AmountChip(
                          label: 'Amount Paid',
                          value:
                              '₹${double.tryParse(data['amount_paid']?.toString() ?? '0')?.toStringAsFixed(2) ?? '—'}',
                          color: cs.onSurface,
                        ),
                      ),
                      Container(
                          width: 1, height: 36, color: cs.outlineVariant),
                      Expanded(
                        child: _AmountChip(
                          label: 'Already Refunded',
                          value: '₹${alreadyRefunded.toStringAsFixed(2)}',
                          color: AppColors.warning,
                        ),
                      ),
                      Container(
                          width: 1, height: 36, color: cs.outlineVariant),
                      Expanded(
                        child: _AmountChip(
                          label: 'Max Refundable',
                          value: '₹${netRefundable.toStringAsFixed(2)}',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                // Past refunds on this booking
                if ((data['past_refunds'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _PastRefundsList(
                      refunds: data['past_refunds'] as List),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _SnapshotRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AmountChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PastRefundsList extends StatelessWidget {
  final List refunds;
  const _PastRefundsList({required this.refunds});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIOR REFUNDS ON THIS BOOKING',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        ...refunds.map((r) {
          final m = r as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.undo_rounded,
                    color: AppColors.warning, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '₹${m['refund_amount'] ?? '—'}  •  ${m['status'] ?? '—'}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (m['is_full_refund'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RefundTypeToggle extends StatelessWidget {
  final bool isFullRefund;
  final ValueChanged<bool> onChanged;
  const _RefundTypeToggle(
      {required this.isFullRefund, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Full Refund',
            icon: Icons.undo_rounded,
            selected: isFullRefund,
            onTap: () => onChanged(true),
            selectedColor: AppColors.error,
          ),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          _ToggleOption(
            label: 'Partial Refund',
            icon: Icons.currency_rupee_rounded,
            selected: !isFullRefund,
            onTap: () => onChanged(false),
            selectedColor: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? selectedColor : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final double maxRefundable;

  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.maxRefundable,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Refund Amount (₹) *',
            hintText: '0.00',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Max: ₹${maxRefundable.toStringAsFixed(2)}',
              style: TextStyle(
                color: maxRefundable > 0
                    ? AppColors.success
                    : cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final String? submitError;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.isSubmitting,
    required this.submitError,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (submitError != null) ...[
          _InlineError(message: submitError!),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: isSubmitting ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isSubmitting
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.error, Color(0xFFB91C1C)],
                    ),
              color: isSubmitting ? AppColors.textDisabled : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSubmitting
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.undo_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Issue Refund',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLookupHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.manage_search_rounded,
                color: cs.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter a Booking ID to begin',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search for a booking above to see payment details\nand issue a refund as needed.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'Inter',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String bookingNumber;
  final String userName;
  final double amount;
  final String reason;
  final bool isFullRefund;

  const _ConfirmDialog({
    required this.bookingNumber,
    required this.userName,
    required this.amount,
    required this.reason,
    required this.isFullRefund,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Confirm Refund',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to issue a ${isFullRefund ? 'FULL' : 'PARTIAL'} refund. This action cannot be undone.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _DialogRow(label: 'Booking', value: '#$bookingNumber'),
          _DialogRow(label: 'Customer', value: userName),
          _DialogRow(
              label: 'Refund Amount',
              value: '₹${amount.toStringAsFixed(2)}',
              valueColor: AppColors.error),
          _DialogRow(label: 'Reason', value: reason),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Confirm Refund',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DialogRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History tile
// ─────────────────────────────────────────────────────────────────────────────
class _RefundHistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RefundHistoryTile({required this.data});

  String _fmt(dynamic dt) {
    if (dt == null) return '—';
    try {
      return _formatDateTime(DateTime.parse(dt.toString()).toLocal());
    } catch (_) {
      return dt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFullRefund = data['is_full_refund'] == true;
    final statusStr = (data['status'] ?? '').toString();
    final isSucceeded = statusStr == 'succeeded';

    final accentColor =
        isSucceeded ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusStr.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (isFullRefund)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FULL',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '₹${data['refund_amount'] ?? '—'}',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Booking & provider
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Booking #${data['booking_number'] ?? '—'}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  (data['payment_provider'] ?? '—').toString().toUpperCase(),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Reason
          if ((data['reason'] ?? '').toString().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['reason'].toString(),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          // Issued by & date
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                data['initiated_by_email'] ?? '—',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded,
                  size: 11, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                _fmt(data['created_at']),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
