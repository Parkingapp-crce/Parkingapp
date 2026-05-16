import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String phone;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String role;
  @JsonKey(name: 'approval_status')
  final String approvalStatus;
  @JsonKey(name: 'approval_notes')
  final String approvalNotes;
  @JsonKey(name: 'approved_at')
  final String? approvedAt;
  final String? society;
  @JsonKey(name: 'society_name')
  final String? societyName;
  @JsonKey(name: 'flat_number')
  final String? flatNumber;
  @JsonKey(name: 'floor_number')
  final String? floorNumber;
  @JsonKey(name: 'can_scan_entry', defaultValue: false)
  final bool canScanEntry;
  @JsonKey(name: 'can_scan_exit', defaultValue: false)
  final bool canScanExit;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    this.approvalStatus = 'approved',
    this.approvalNotes = '',
    this.approvedAt,
    this.society,
    this.societyName,
    this.flatNumber,
    this.floorNumber,
    this.canScanEntry = false,
    this.canScanExit = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool get isApproved => approvalStatus == 'approved';
  bool get isPendingApproval => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';
}
