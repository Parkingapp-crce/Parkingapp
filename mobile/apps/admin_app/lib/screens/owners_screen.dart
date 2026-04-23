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
          IconButton(
            onPressed: _loadOwners,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Loading owners...')
            : _error != null && _owners.isEmpty
                ? AppErrorWidget(message: _error!, onRetry: _loadOwners)
                : RefreshIndicator(
                    onRefresh: _loadOwners,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Manage approved parking owners and view their slots.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
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
                          ..._owners.map((owner) => _OwnerCard(
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
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final Map<String, dynamic> owner;
  final VoidCallback onTap;

  const _OwnerCard({
    required this.owner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          owner['user_name'] ?? 'Owner',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(owner['user_email'] ?? ''),
            Text(owner['user_phone'] ?? ''),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
