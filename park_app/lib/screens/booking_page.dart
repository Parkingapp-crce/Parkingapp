import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'qr_code_page.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> lot;
  const BookingPage({super.key, required this.lot});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF0D1B0F);
  final Color textGrey = const Color(0xFF6B7280);

  final vehicleController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  bool isLoading = false;
  String selectedVehicleType = '4-wheeler';

  double get totalAmount {
    if (startTime == null || endTime == null) return 0;
    final hours = endTime!.difference(startTime!).inMinutes / 60;
    return hours * double.parse(widget.lot['price_per_hour'].toString());
  }

  Future<void> pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        startTime = picked;
        endTime = null;
      } else {
        endTime = picked;
      }
    });
  }

  Future<void> confirmBooking() async {
    if (vehicleController.text.trim().isEmpty) {
      _snack('Please enter vehicle number');
      return;
    }
    if (startTime == null || endTime == null) {
      _snack('Please select start and end time');
      return;
    }
    if (endTime!.isBefore(startTime!)) {
      _snack('End time must be after start time');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.bookSlot(
        parkingLotId: widget.lot['id'],
        vehicleNumber: vehicleController.text.trim(),
        vehicleType: selectedVehicleType,
        startTime: startTime!.toUtc().toIso8601String(),
        endTime: endTime!.toUtc().toIso8601String(),
      );

      if (response['booking'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodePage(
              booking: response['booking'],
              qrCode: response['qr_code'],
            ),
          ),
        );
      } else {
        _snack(response['error'] ?? 'Booking failed');
      }
    } catch (e) {
      _snack('Server error. Try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String formatDt(DateTime? dt) {
    if (dt == null) return 'Tap to select';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Book Parking',
            style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        iconTheme: IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lot info card
            _sectionCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.local_parking_rounded,
                        color: primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lot['name'],
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textDark)),
                        const SizedBox(height: 4),
                        Text(
                            '${widget.lot['address']}, ${widget.lot['city']}',
                            style: TextStyle(color: textGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('₹${widget.lot['price_per_hour']}/hr',
                      style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle type selector
            _label('Vehicle Type'),
            const SizedBox(height: 8),
            _sectionCard(
              child: Row(
                children: [
                  _vehicleTypeOption(
                    label: '2-Wheeler',
                    icon: Icons.two_wheeler_rounded,
                    value: '2-wheeler',
                  ),
                  const SizedBox(width: 12),
                  _vehicleTypeOption(
                    label: '4-Wheeler',
                    icon: Icons.directions_car_rounded,
                    value: '4-wheeler',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle number
            _label('Vehicle Number'),
            const SizedBox(height: 8),
            _sectionCard(
              child: TextField(
                controller: vehicleController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: selectedVehicleType == '2-wheeler'
                      ? 'e.g. MH04AB1234'
                      : 'e.g. MH04AB1234',
                  hintStyle: TextStyle(color: textGrey),
                  prefixIcon: Icon(
                    selectedVehicleType == '2-wheeler'
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    color: primaryGreen,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Start time
            _label('Start Time'),
            const SizedBox(height: 8),
            _timePicker(
              label: formatDt(startTime),
              onTap: () => pickDateTime(isStart: true),
            ),

            const SizedBox(height: 16),

            // End time
            _label('End Time'),
            const SizedBox(height: 8),
            _timePicker(
              label: formatDt(endTime),
              onTap: () => pickDateTime(isStart: false),
            ),

            const SizedBox(height: 24),

            // Amount summary
            if (startTime != null && endTime != null && totalAmount > 0)
              _sectionCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration',
                            style: TextStyle(color: textGrey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${endTime!.difference(startTime!).inMinutes ~/ 60}h '
                          '${endTime!.difference(startTime!).inMinutes % 60}m',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: textDark),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Amount',
                            style: TextStyle(color: textGrey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Booking',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _vehicleTypeOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = selectedVehicleType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedVehicleType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : const Color(0xFFF5F9F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryGreen : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : textGrey,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : textGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: textDark, fontWeight: FontWeight.w700, fontSize: 14));

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
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
        child: child,
      );

  Widget _timePicker({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
              Icon(Icons.access_time_rounded, color: primaryGreen),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: label == 'Tap to select' ? textGrey : textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}