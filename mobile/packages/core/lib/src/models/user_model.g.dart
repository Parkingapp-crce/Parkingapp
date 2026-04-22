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
  society: json['society'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'phone': instance.phone,
  'full_name': instance.fullName,
  'role': instance.role,
  'society': instance.society,
  'created_at': instance.createdAt,
};
