import 'package:json_annotation/json_annotation.dart';

part 'penalty_model.g.dart';

@JsonSerializable()
class PenaltyModel {
  final String id;
  final String booking;
  @JsonKey(name: 'booking_number')
  final String? bookingNumber;
  final String user;
  @JsonKey(name: 'overstay_minutes')
  final int overstayMinutes;
  final String amount;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const PenaltyModel({
    required this.id,
    required this.booking,
    this.bookingNumber,
    required this.user,
    required this.overstayMinutes,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PenaltyModel.fromJson(Map<String, dynamic> json) =>
      _$PenaltyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PenaltyModelToJson(this);

  bool get isUnpaid => status == 'unpaid';
}
