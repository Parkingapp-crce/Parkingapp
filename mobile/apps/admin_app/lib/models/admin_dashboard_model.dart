import 'package:core/core.dart';

class GateActivityModel {
  final String id;
  final String eventType;
  final String result;
  final String errorMessage;
  final String scannedAt;
  final String guardName;
  final String bookingNumber;
  final String vehicleNumber;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String slotNumber;
  final String paymentStatus;
  final String? entryTime;
  final String? exitTime;

  const GateActivityModel({
    required this.id,
    required this.eventType,
    required this.result,
    required this.errorMessage,
    required this.scannedAt,
    required this.guardName,
    required this.bookingNumber,
    required this.vehicleNumber,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.slotNumber,
    required this.paymentStatus,
    this.entryTime,
    this.exitTime,
  });

  factory GateActivityModel.fromJson(Map<String, dynamic> json) {
    return GateActivityModel(
      id: json['id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      result: json['result'] as String? ?? '',
      errorMessage: json['error_message'] as String? ?? '',
      scannedAt: json['scanned_at'] as String? ?? '',
      guardName: json['guard_name'] as String? ?? '',
      bookingNumber: json['booking_number'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      ownerPhone: json['owner_phone'] as String? ?? '',
      ownerEmail: json['owner_email'] as String? ?? '',
      slotNumber: json['slot_number'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'unknown',
      entryTime: json['entry_time'] as String?,
      exitTime: json['exit_time'] as String?,
    );
  }
}

class AdminDashboardModel {
  final int totalSlots;
  final int availableSlots;
  final int reservedSlots;
  final int occupiedSlots;
  final int blockedSlots;
  final int activeBookings;
  final int completedToday;
  final int pendingGuardRequests;
  final int approvedGuards;
  final List<BookingModel> currentlyParked;
  final List<GateActivityModel> recentGateActivity;

  const AdminDashboardModel({
    required this.totalSlots,
    required this.availableSlots,
    required this.reservedSlots,
    required this.occupiedSlots,
    required this.blockedSlots,
    required this.activeBookings,
    required this.completedToday,
    required this.pendingGuardRequests,
    required this.approvedGuards,
    required this.currentlyParked,
    required this.recentGateActivity,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalSlots: _asInt(json['total_slots']),
      availableSlots: _asInt(json['available_slots']),
      reservedSlots: _asInt(json['reserved_slots']),
      occupiedSlots: _asInt(json['occupied_slots']),
      blockedSlots: _asInt(json['blocked_slots']),
      activeBookings: _asInt(json['active_bookings']),
      completedToday: _asInt(json['completed_today']),
      pendingGuardRequests: _asInt(json['pending_guard_requests']),
      approvedGuards: _asInt(json['approved_guards']),
      currentlyParked: (json['currently_parked'] as List? ?? const [])
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentGateActivity: (json['recent_gate_activity'] as List? ?? const [])
          .map(
            (item) => GateActivityModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
