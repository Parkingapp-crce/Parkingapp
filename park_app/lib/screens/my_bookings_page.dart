import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'qr_code_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF0D1B0F);
  final Color textGrey = const Color(0xFF6B7280);

  late TabController _tabController;
  List<dynamic> allBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final data = await ApiService.getMyBookings();
      setState(() {
        allBookings = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get activeBookings => allBookings
      .where((b) => ['pending', 'confirmed'].contains(b['status']))
      .toList();

  List<dynamic> get pastBookings => allBookings
      .where((b) => ['completed', 'cancelled'].contains(b['status']))
      .toList();

  Future<void> cancelBooking(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.cancelBooking(bookingId);
    if (response['message'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')));
      fetchBookings();
    }
  }

  String formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
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
        title: Text('My Bookings',
            style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        iconTheme: IconThemeData(color: textDark),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryGreen,
          labelColor: primaryGreen,
          unselectedLabelColor: textGrey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: 'Active (${activeBookings.length})'),
            Tab(text: 'Past (${pastBookings.length})'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(activeBookings, isActive: true),
                _buildList(pastBookings, isActive: false),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 56, color: textGrey),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active bookings' : 'No past bookings',
              style: TextStyle(
                  color: textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchBookings,
      color: primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) =>
            _buildBookingCard(bookings[index], isActive: isActive),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking,
      {required bool isActive}) {
    final status = booking['status'] ?? '';
    final statusColor = {
      'confirmed': primaryGreen,
      'pending': Colors.orange,
      'completed': Colors.blue,
      'cancelled': Colors.red,
    }[status] ?? textGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking['parking_lot_name'] ?? '-',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.directions_car_rounded,
                booking['vehicle_number'] ?? '-'),
            const SizedBox(height: 6),
            _row(Icons.play_arrow_rounded,
                formatTime(booking['start_time'] ?? '')),
            const SizedBox(height: 6),
            _row(
                Icons.stop_rounded, formatTime(booking['end_time'] ?? '')),
            const SizedBox(height: 6),
            _row(Icons.currency_rupee_rounded,
                '₹${booking['amount']}'),
            if (isActive) ...[
              const SizedBox(height: 14),
              Divider(color: Colors.grey[100]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => cancelBooking(booking['id']),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Colors.red),
                      label: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRCodePage(
                              booking: booking,
                              qrCode: {'code': booking['id'].toString()},
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_rounded, size: 16),
                      label: const Text('View QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 15, color: textGrey),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(color: textGrey, fontSize: 13)),
        ],
      );
}