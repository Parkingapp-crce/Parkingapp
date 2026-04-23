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
          (data['results'] as List)
              .map((item) => _JoinRequestRecord.fromJson(item as Map<String, dynamic>)),
        );
      } else if (data is List) {
        requests.addAll(
          data.map((item) => _JoinRequestRecord.fromJson(item as Map<String, dynamic>)),
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
            data: {
              'action': approve ? 'approve' : 'reject',
              'notes': '',
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Join request approved' : 'Join request rejected'),
          backgroundColor: approve ? AppColors.success : AppColors.warning,
        ),
      );
      await _loadRequests();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Requests'),
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Loading join requests...')
            : _error != null && _requests.isEmpty
                ? AppErrorWidget(message: _error!, onRetry: _loadRequests)
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Approve residents before they can access parking features.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        if (_requests.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.how_to_reg_outlined,
                            title: 'No pending requests',
                            subtitle: 'New resident join requests will appear here.',
                          )
                        else
                          ..._requests.map((request) => _JoinRequestCard(
                                request: request,
                                onApprove: () => _decide(request, true),
                                onReject: () => _decide(request, false),
                              )),
                      ],
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
                const Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.userEmail),
            const SizedBox(height: 4),
            Text(request.userPhone),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_circle_outline,
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
