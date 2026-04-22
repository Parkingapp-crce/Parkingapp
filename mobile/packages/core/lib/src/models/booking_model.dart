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
  final String amount;
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
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    required this.startTime,
    required this.endTime,
    this.actualEntry,
    this.actualExit,
    required this.status,
    required this.amount,
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
}
