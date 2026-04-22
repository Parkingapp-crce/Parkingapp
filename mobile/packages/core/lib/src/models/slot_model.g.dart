// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotModel _$SlotModelFromJson(Map<String, dynamic> json) => SlotModel(
  id: json['id'] as String,
  society: json['society'] as String,
  slotNumber: json['slot_number'] as String,
  floor: json['floor'] as String? ?? '',
  slotType: json['slot_type'] as String,
  state: json['state'] as String,
  ownershipType: json['ownership_type'] as String,
  owner: json['owner'] as String?,
  hourlyRate: json['hourly_rate'] as String,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$SlotModelToJson(SlotModel instance) => <String, dynamic>{
  'id': instance.id,
  'society': instance.society,
  'slot_number': instance.slotNumber,
  'floor': instance.floor,
  'slot_type': instance.slotType,
  'state': instance.state,
  'ownership_type': instance.ownershipType,
  'owner': instance.owner,
  'hourly_rate': instance.hourlyRate,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
};
