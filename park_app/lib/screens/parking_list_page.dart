import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'booking_page.dart';

class ParkingListPage extends StatefulWidget {
  const ParkingListPage({super.key});

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

class _ParkingListPageState extends State<ParkingListPage> {
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF0D1B0F);
  final Color textGrey = const Color(0xFF6B7280);

  List<dynamic> allLots = [];
  List<dynamic> filteredLots = [];
  bool isLoading = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLots();
  }

  Future<void> fetchLots() async {
    try {
      final data = await ApiService.getParkingLots();
      setState(() {
        allLots = data['parking_lots'] ?? [];
        filteredLots = allLots;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void filterLots(String query) {
    setState(() {
      filteredLots = allLots.where((lot) {
        final city = lot['city'].toString().toLowerCase();
        final name = lot['name'].toString().toLowerCase();
        return city.contains(query.toLowerCase()) ||
            name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Find Parking',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: searchController,
              onChanged: filterLots,
              decoration: InputDecoration(
                hintText: 'Search by city or name...',
                hintStyle: TextStyle(color: textGrey, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: primaryGreen),
                filled: true,
                fillColor: const Color(0xFFF5F9F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : filteredLots.isEmpty
                    ? Center(
                        child: Text(
                          'No parking lots found.',
                          style: TextStyle(color: textGrey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchLots,
                        color: primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLots.length,
                          itemBuilder: (context, index) {
                            final lot = filteredLots[index];
                            return _buildLotCard(lot);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot) {
    final available = lot['available_slots'] ?? 0;
    final total = lot['total_slots'] ?? 0;
    final isFull = available == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.local_parking_rounded,
                      color: primaryGreen, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: textGrey),
                          const SizedBox(width: 3),
                          Text(
                            '${lot['address']}, ${lot['city']}',
                            style:
                                TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₹${lot['price_per_hour']}/hr',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey[100], height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _infoChip(Icons.access_time_rounded,
                    '${lot['opening_time']} - ${lot['closing_time']}',
                    Colors.orange),
                const SizedBox(width: 10),
                _infoChip(
                  Icons.directions_car_rounded,
                  '$available/$total slots',
                  isFull ? Colors.red : primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFull
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(lot: lot),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isFull ? 'Fully Booked' : 'Book Now',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}