// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'society_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocietyModel _$SocietyModelFromJson(Map<String, dynamic> json) => SocietyModel(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  pincode: json['pincode'] as String,
  latitude: SocietyModel._toDouble(json['latitude']),
  longitude: SocietyModel._toDouble(json['longitude']),
  contactEmail: json['contact_email'] as String,
  contactPhone: json['contact_phone'] as String,
  isActive: json['is_active'] as bool? ?? true,
  totalSlots: (json['total_slots'] as num?)?.toInt(),
  availableSlots: (json['available_slots'] as num?)?.toInt(),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$SocietyModelToJson(SocietyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'contact_email': instance.contactEmail,
      'contact_phone': instance.contactPhone,
      'is_active': instance.isActive,
      'total_slots': instance.totalSlots,
      'available_slots': instance.availableSlots,
      'created_at': instance.createdAt,
    };
