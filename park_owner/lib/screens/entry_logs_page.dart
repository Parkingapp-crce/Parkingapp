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
  final Color primaryGreen = AppColors.primary;
  final Color textDark = AppColors.textPrimary;
  final Color textGrey = AppColors.textSecondary;

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
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Entry Logs',
            style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        iconTheme: IconThemeData(color: textDark),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 56, color: textGrey),
                      const SizedBox(height: 16),
                      Text('No entry logs yet',
                          style: TextStyle(
                              color: textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchLogs,
                  color: primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) =>
                        _buildLogCard(logs[index]),
                  ),
                ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isAllowed = log['entry_status'] == 'allowed';
    final statusColor = isAllowed ? primaryGreen : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAllowed
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: statusColor,
              size: 24,
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
                          fontSize: 13),
                    ),
                    Text(
                      '#${log['id']}',
                      style: TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatTime(log['scanned_at'] ?? ''),
                  style: TextStyle(color: textGrey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scanned by: ${log['scanned_by_name'] ?? '-'}',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}