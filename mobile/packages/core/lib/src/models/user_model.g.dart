// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  fullName: json['full_name'] as String,
  role: json['role'] as String,
  approvalStatus: json['approval_status'] as String? ?? 'approved',
  approvalNotes: json['approval_notes'] as String? ?? '',
  approvedAt: json['approved_at'] as String?,
  society: json['society'] as String?,
  societyName: json['society_name'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'phone': instance.phone,
  'full_name': instance.fullName,
  'role': instance.role,
  'approval_status': instance.approvalStatus,
  'approval_notes': instance.approvalNotes,
  'approved_at': instance.approvedAt,
  'society': instance.society,
  'society_name': instance.societyName,
  'created_at': instance.createdAt,
};
