// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
  id: json['id'] as String,
  bookingNumber: json['booking_number'] as String,
  user: json['user'] as String,
  vehicle: json['vehicle'] == null
      ? null
      : VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
  slot: json['slot'] as String,
  slotNumber: json['slot_number'] as String?,
  societyName: json['society_name'] as String?,
  ownerName: json['owner_name'] as String?,
  ownerEmail: json['owner_email'] as String?,
  ownerPhone: json['owner_phone'] as String?,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  actualEntry: json['actual_entry'] as String?,
  actualExit: json['actual_exit'] as String?,
  status: json['status'] as String,
  amount: json['amount'] as String,
  paymentStatus: json['payment_status'] as String?,
  lockExpiresAt: json['lock_expires_at'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking_number': instance.bookingNumber,
      'user': instance.user,
      'vehicle': instance.vehicle,
      'slot': instance.slot,
      'slot_number': instance.slotNumber,
      'society_name': instance.societyName,
      'owner_name': instance.ownerName,
      'owner_email': instance.ownerEmail,
      'owner_phone': instance.ownerPhone,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'actual_entry': instance.actualEntry,
      'actual_exit': instance.actualExit,
      'status': instance.status,
      'amount': instance.amount,
      'payment_status': instance.paymentStatus,
      'lock_expires_at': instance.lockExpiresAt,
      'created_at': instance.createdAt,
    };
