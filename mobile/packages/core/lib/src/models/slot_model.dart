import 'package:json_annotation/json_annotation.dart';

part 'slot_model.g.dart';

@JsonSerializable()
class SlotModel {
  final String id;
  final String society;
  @JsonKey(name: 'slot_number')
  final String slotNumber;
  final String floor;
  @JsonKey(name: 'slot_type')
  final String slotType;
  final String state;
  @JsonKey(name: 'ownership_type')
  final String ownershipType;
  final String? owner;
  @JsonKey(name: 'hourly_rate')
  final String hourlyRate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const SlotModel({
    required this.id,
    required this.society,
    required this.slotNumber,
    this.floor = '',
    required this.slotType,
    required this.state,
    required this.ownershipType,
    this.owner,
    required this.hourlyRate,
    this.isActive = true,
    required this.createdAt,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) =>
      _$SlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$SlotModelToJson(this);

  bool get isAvailable => state == 'available';
  bool get isBlocked => state == 'blocked';
}
