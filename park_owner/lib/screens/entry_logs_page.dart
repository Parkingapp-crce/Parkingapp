import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import '../services/api_service.dart';

class EntryLogsPage extends StatefulWidget {
  const EntryLogsPage({super.key});

  @override
  State<EntryLogsPage> createState() => _EntryLogsPageState();
}

class _EntryLogsPageState extends State<EntryLogsPage> {
  List<dynamic> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      final data = await ApiService.getEntryLogs();
      setState(() {
        logs = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Logs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Inter',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: isLoading
          ? const LoadingWidget(message: 'Fetching logs...')
          : logs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'No logs found',
                  subtitle: 'You haven\'t scanned any QRs yet.',
                )
              : RefreshIndicator(
                  onRefresh: fetchLogs,
                  color: AppColors.primaryLight,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    itemCount: logs.length,
                    itemBuilder: (context, index) =>
                        _buildLogCard(logs[index]),
                  ),
                ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isAllowed = log['entry_status'] == 'allowed';
    final statusColor =
        isAllowed ? AppColors.success : const Color(0xFFFF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAllowed
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAllowed ? 'ALLOWED' : 'DENIED',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      '#${log['id']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatTime(log['scanned_at'] ?? ''),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scanned by: ${log['scanned_by_name'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
