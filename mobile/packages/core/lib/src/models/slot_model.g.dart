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
  ownerName: json['owner_name'] as String?,
  hourlyRate: json['hourly_rate'] as String,
  availableFrom: json['available_from'] as String?,
  availableTo: json['available_to'] as String?,
  approvalStatus: json['approval_status'] as String? ?? 'approved',
  approvalNotes: json['approval_notes'] as String? ?? '',
  approvedAt: json['approved_at'] as String?,
  createdBy: json['created_by'] as String?,
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
  'owner_name': instance.ownerName,
  'approval_status': instance.approvalStatus,
  'approval_notes': instance.approvalNotes,
  'approved_at': instance.approvedAt,
  'created_by': instance.createdBy,
  'hourly_rate': instance.hourlyRate,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
  'available_from': instance.availableFrom,
  'available_to': instance.availableTo,
};
