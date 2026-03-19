import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@JsonSerializable()
class VehicleModel {
  final String id;
  @JsonKey(name: 'vehicle_type')
  final String vehicleType;
  @JsonKey(name: 'registration_no')
  final String registrationNo;
  @JsonKey(name: 'make_model')
  final String makeModel;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const VehicleModel({
    required this.id,
    required this.vehicleType,
    required this.registrationNo,
    this.makeModel = '',
    this.isActive = true,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);
}
