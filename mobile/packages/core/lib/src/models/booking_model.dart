import 'package:json_annotation/json_annotation.dart';

import 'vehicle_model.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  final String id;
  @JsonKey(name: 'booking_number')
  final String bookingNumber;
  final String user;
  final VehicleModel? vehicle;
  final String slot;
  @JsonKey(name: 'slot_number')
  final String? slotNumber;
  @JsonKey(name: 'society_name')
  final String? societyName;
  @JsonKey(name: 'society_address')
  final String? societyAddress;
  @JsonKey(name: 'society_city')
  final String? societyCity;
  @JsonKey(name: 'society_state')
  final String? societyState;
  @JsonKey(name: 'society_latitude', fromJson: _toDouble)
  final double? societyLatitude;
  @JsonKey(name: 'society_longitude', fromJson: _toDouble)
  final double? societyLongitude;
  @JsonKey(name: 'owner_name')
  final String? ownerName;
  @JsonKey(name: 'owner_email')
  final String? ownerEmail;
  @JsonKey(name: 'owner_phone')
  final String? ownerPhone;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  @JsonKey(name: 'actual_entry')
  final String? actualEntry;
  @JsonKey(name: 'actual_exit')
  final String? actualExit;
  final String status;
  @JsonKey(name: 'base_amount')
  final String? baseAmount;
  @JsonKey(name: 'surge_amount')
  final String? surgeAmount;
  @JsonKey(name: 'surge_multiplier')
  final String? surgeMultiplier;
  final String amount;
  @JsonKey(name: 'amount_paid')
  final String? amountPaid;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;
  @JsonKey(name: 'lock_expires_at')
  final String? lockExpiresAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.user,
    this.vehicle,
    required this.slot,
    this.slotNumber,
    this.societyName,
    this.societyAddress,
    this.societyCity,
    this.societyState,
    this.societyLatitude,
    this.societyLongitude,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    required this.startTime,
    required this.endTime,
    this.actualEntry,
    this.actualExit,
    required this.status,
    this.baseAmount,
    this.surgeAmount,
    this.surgeMultiplier,
    required this.amount,
    this.amountPaid,
    this.paymentStatus,
    this.lockExpiresAt,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) =>

      _$BookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);

  bool get isPendingPayment => status == 'pending_payment';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaymentCompleted => paymentStatus == 'captured';

  String get paymentStatusLabel {
    if (isConfirmed || isActive || isCompleted) {
      return 'PAYMENT COMPLETED';
    }
    switch (paymentStatus) {
      case 'captured':
        return 'PAYMENT COMPLETED';
      case 'failed':
        return 'PAYMENT FAILED';
      case 'refunded':
        return 'PAYMENT REFUNDED';
      case 'created':
      case 'unpaid':
      case null:
        return 'PAYMENT PENDING';
      default:
        return paymentStatus!.replaceAll('_', ' ').toUpperCase();
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
