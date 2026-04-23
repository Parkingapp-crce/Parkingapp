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
          (data['results'] as List).map((item) => SlotModel.fromJson(item as Map<String, dynamic>)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ownerName),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading owner details...')
          : _error != null && _slots.isEmpty
              ? AppErrorWidget(message: _error!, onRetry: _loadOwnerSlots)
              : RefreshIndicator(
                  onRefresh: _loadOwnerSlots,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Icon(Icons.person, color: AppColors.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.ownerName,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            'APPROVED',
                                            style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              _DetailRow(icon: Icons.email_outlined, label: 'Email', value: widget.ownerEmail),
                              const SizedBox(height: 12),
                              _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: widget.ownerPhone),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Owner Slots',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                        ..._slots.map((slot) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => context.push('/slots/${slot.id}'),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    slot.slotType == 'bike'
                                        ? Icons.two_wheeler
                                        : Icons.directions_car,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  'Slot ${slot.slotNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${slot.slotType.toUpperCase()} | Rate: \u20B9${slot.hourlyRate}/hr'),
                                    Text(
                                      'Status: ${slot.approvalStatus.toUpperCase()}',
                                      style: TextStyle(
                                        color: slot.approvalStatus == 'approved'
                                            ? AppColors.success
                                            : slot.approvalStatus == 'rejected'
                                                ? AppColors.error
                                                : AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => context.push('/slots/${slot.id}'),
                                ),
                              ),
                            )),
                    ],
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
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
