// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) => VehicleModel(
  id: json['id'] as String,
  vehicleType: json['vehicle_type'] as String,
  registrationNo: json['registration_no'] as String,
  makeModel: json['make_model'] as String? ?? '',
  isActive: json['is_active'] as bool? ?? true,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_type': instance.vehicleType,
      'registration_no': instance.registrationNo,
      'make_model': instance.makeModel,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };
