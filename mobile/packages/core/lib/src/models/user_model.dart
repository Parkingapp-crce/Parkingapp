import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
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
  final String? createdAt; // Made nullable for safety

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
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    fullName,
    role,
    approvalStatus,
    approvalNotes,
    approvedAt,
    society,
    societyName,
    flatNumber,
    floorNumber,
    canScanEntry,
    canScanExit,
    createdAt,
  ];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$UserModelFromJson(json);
    } catch (e) {
      // Return a minimal valid model if parsing fails to prevent app crash
      return UserModel(
        id: json['id']?.toString() ?? 'unknown',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? 'Unknown User',
        role: json['role']?.toString() ?? 'user',
        approvalStatus: json['approval_status']?.toString() ?? 'pending',
        createdAt: json['created_at']?.toString(),
      );
    }
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool get isApproved => approvalStatus == 'approved';
  bool get isPendingApproval => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';
}
