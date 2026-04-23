import 'package:json_annotation/json_annotation.dart';

part 'society_model.g.dart';

@JsonSerializable()
class SocietyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  @JsonKey(fromJson: _toDouble)
  final double? latitude;
  @JsonKey(fromJson: _toDouble)
  final double? longitude;
  @JsonKey(name: 'contact_email')
  final String contactEmail;
  @JsonKey(name: 'contact_phone')
  final String contactPhone;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'total_slots')
  final int? totalSlots;
  @JsonKey(name: 'available_slots')
  final int? availableSlots;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const SocietyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.contactEmail,
    required this.contactPhone,
    this.isActive = true,
    this.totalSlots,
    this.availableSlots,
    required this.createdAt,
  });

  factory SocietyModel.fromJson(Map<String, dynamic> json) =>
      _$SocietyModelFromJson(json);

  Map<String, dynamic> toJson() => _$SocietyModelToJson(this);

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
