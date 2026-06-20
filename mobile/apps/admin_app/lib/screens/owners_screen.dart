import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class OwnersScreen extends StatefulWidget {
  const OwnersScreen({super.key});

  @override
  State<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends State<OwnersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _owners = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwners();
    });
  }

  String? get _societyId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  Future<void> _loadOwners() async {
    final societyId = _societyId;
    if (societyId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiClient>().get(
        ApiEndpoints.societyJoinRequests(societyId),
        queryParameters: {'status': 'approved'},
      );
      final data = response.data;
      final List<Map<String, dynamic>> owners = [];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        owners.addAll(List<Map<String, dynamic>>.from(data['results']));
      } else if (data is List) {
        owners.addAll(List<Map<String, dynamic>>.from(data));
      }

      setState(() {
        _isLoading = false;
        _owners = owners;
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
        title: const Text('Parking Owners'),
        actions: [
          IconButton(onPressed: _loadOwners, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Loading owners...')
            : _error != null && _owners.isEmpty
            ? AppErrorWidget(message: _error!, onRetry: _loadOwners)
            : RefreshIndicator(
                onRefresh: _loadOwners,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Manage approved parking owners and view their slots.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_owners.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.people_alt_outlined,
                            title: 'No owners yet',
                            subtitle: 'Approved owners will appear here.',
                          )
                        else
                          ..._owners.map(
                            (owner) => _OwnerCard(
                              owner: owner,
                              onTap: () {
                                context.push(
                                  '/owners/${owner['user']}',
                                  extra: {
                                    'name': owner['user_name'],
                                    'email': owner['user_email'],
                                    'phone': owner['user_phone'],
                                  },
                                );
                              },
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

class _OwnerCard extends StatelessWidget {
  final Map<String, dynamic> owner;
  final VoidCallback onTap;

  const _OwnerCard({required this.owner, required this.onTap});

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
    final name = owner['user_name'] ?? 'Owner';

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  _getInitials(name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            owner['user_email'] ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            owner['user_phone'] ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
