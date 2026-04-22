// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'penalty_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PenaltyModel _$PenaltyModelFromJson(Map<String, dynamic> json) => PenaltyModel(
  id: json['id'] as String,
  booking: json['booking'] as String,
  bookingNumber: json['booking_number'] as String?,
  user: json['user'] as String,
  overstayMinutes: (json['overstay_minutes'] as num).toInt(),
  amount: json['amount'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PenaltyModelToJson(PenaltyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking': instance.booking,
      'booking_number': instance.bookingNumber,
      'user': instance.user,
      'overstay_minutes': instance.overstayMinutes,
      'amount': instance.amount,
      'status': instance.status,
      'created_at': instance.createdAt,
    };
