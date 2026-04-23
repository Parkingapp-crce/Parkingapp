import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_exceptions.dart';
import '../theme/app_colors.dart';
import 'empty_state_widget.dart';
import 'error_widget.dart';
import 'loading_widget.dart';

class NotificationInboxScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String title;

  const NotificationInboxScreen({
    super.key,
    required this.apiClient,
    this.title = 'Notifications',
  });

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  bool _isLoading = true;
  String? _error;
  List<_NotificationItem> _notifications = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.apiClient.get(ApiEndpoints.notifications);
      final data = response.data;
      final notifications = <_NotificationItem>[];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        notifications.addAll(
          (data['results'] as List)
              .map((item) => _NotificationItem.fromJson(item as Map<String, dynamic>)),
        );
      } else if (data is List) {
        notifications.addAll(
          data.map((item) => _NotificationItem.fromJson(item as Map<String, dynamic>)),
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notifications = notifications;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markAsRead(_NotificationItem notification) async {
    if (notification.isRead) return;

    try {
      final response = await widget.apiClient.patch(
        ApiEndpoints.notificationRead(notification.id),
      );
      final updated = _NotificationItem.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update notification.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (unreadCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$unreadCount unread',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Loading notifications...')
            : _error != null && _notifications.isEmpty
                ? AppErrorWidget(message: _error!, onRetry: _loadNotifications)
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_notifications.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.notifications_none,
                            title: 'No notifications',
                            subtitle: 'Updates from approvals and requests will appear here.',
                          )
                        else
                          ..._notifications.map(
                            (notification) => _NotificationCard(
                              notification: notification,
                              onTap: () => _markAsRead(notification),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> payload;
  final bool isRead;
  final String createdAt;

  const _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    return _NotificationItem(
      id: json['id'] as String,
      type: json['notification_type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = notification.isRead ? AppColors.textSecondary : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.12),
          child: Icon(
            _iconFor(notification.type),
            color: accentColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(notification.message),
        ),
        trailing: notification.isRead
            ? const Icon(Icons.done_all, size: 18, color: AppColors.textSecondary)
            : const Icon(Icons.fiber_manual_record, size: 12, color: AppColors.primary),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'join_request':
        return Icons.how_to_reg;
      case 'join_approved':
        return Icons.verified;
      case 'join_rejected':
        return Icons.cancel_outlined;
      case 'slot_pending':
        return Icons.local_parking;
      case 'slot_approved':
        return Icons.check_circle_outline;
      case 'slot_rejected':
        return Icons.highlight_off;
      default:
        return Icons.notifications;
    }
  }
}
