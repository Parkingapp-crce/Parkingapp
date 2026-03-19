import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  final String id;
  final String? booking;
  final String? penalty;
  @JsonKey(name: 'payment_type')
  final String paymentType;
  final String amount;
  @JsonKey(name: 'razorpay_order_id')
  final String razorpayOrderId;
  @JsonKey(name: 'razorpay_payment_id')
  final String? razorpayPaymentId;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const PaymentModel({
    required this.id,
    this.booking,
    this.penalty,
    required this.paymentType,
    required this.amount,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);
}
