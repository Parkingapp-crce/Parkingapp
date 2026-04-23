// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentModel _$PaymentModelFromJson(Map<String, dynamic> json) => PaymentModel(
  id: json['id'] as String,
  booking: json['booking'] as String?,
  penalty: json['penalty'] as String?,
  paymentType: json['payment_type'] as String,
  amount: json['amount'] as String,
  razorpayOrderId: json['razorpay_order_id'] as String,
  razorpayPaymentId: json['razorpay_payment_id'] as String?,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PaymentModelToJson(PaymentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking': instance.booking,
      'penalty': instance.penalty,
      'payment_type': instance.paymentType,
      'amount': instance.amount,
      'razorpay_order_id': instance.razorpayOrderId,
      'razorpay_payment_id': instance.razorpayPaymentId,
      'status': instance.status,
      'created_at': instance.createdAt,
    };
