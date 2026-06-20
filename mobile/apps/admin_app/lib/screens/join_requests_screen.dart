import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<_JoinRequestRecord> _requests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  String? get _societyId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  Future<void> _loadRequests() async {
    final societyId = _societyId;
    if (societyId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiClient>().get(
        ApiEndpoints.societyJoinRequests(societyId),
        queryParameters: {'status': 'pending'},
      );
      final data = response.data;
      final requests = <_JoinRequestRecord>[];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        requests.addAll(
          (data['results'] as List).map(
            (item) => _JoinRequestRecord.fromJson(item as Map<String, dynamic>),
          ),
        );
      } else if (data is List) {
        requests.addAll(
          data.map(
            (item) => _JoinRequestRecord.fromJson(item as Map<String, dynamic>),
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _requests = requests;
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _decide(_JoinRequestRecord request, bool approve) async {
    final societyId = _societyId;
    if (societyId == null) return;

    try {
      await context.read<ApiClient>().post(
        ApiEndpoints.societyJoinRequestDecision(societyId, request.id),
        data: {'action': approve ? 'approve' : 'reject', 'notes': ''},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Join request approved' : 'Join request rejected',
          ),
          backgroundColor: approve ? AppColors.success : AppColors.warning,
        ),
      );
      await _loadRequests();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Requests'),
        actions: [
          IconButton(onPressed: _loadRequests, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Loading join requests...')
            : _error != null && _requests.isEmpty
            ? AppErrorWidget(message: _error!, onRetry: _loadRequests)
            : RefreshIndicator(
                onRefresh: _loadRequests,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Approve residents before they can access parking features.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_requests.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.how_to_reg_outlined,
                            title: 'No pending requests',
                            subtitle:
                                'New resident join requests will appear here.',
                          )
                        else
                          ..._requests.map(
                            (request) => _JoinRequestCard(
                              request: request,
                              onApprove: () => _decide(request, true),
                              onReject: () => _decide(request, false),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _JoinRequestRecord {
  final String id;
  final String status;
  final String? notes;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String createdAt;

  const _JoinRequestRecord({
    required this.id,
    required this.status,
    required this.notes,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.createdAt,
  });

  factory _JoinRequestRecord.fromJson(Map<String, dynamic> json) {
    return _JoinRequestRecord(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      userName: json['user_name'] as String? ?? 'Resident',
      userEmail: json['user_email'] as String? ?? '',
      userPhone: json['user_phone'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final _JoinRequestRecord request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(request.userName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.userName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.userEmail,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.userPhone,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.notes!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: onApprove,
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
