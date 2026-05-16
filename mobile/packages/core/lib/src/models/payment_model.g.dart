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
  currency: json['currency'] as String,
  provider: json['provider'] as String,
  orderReferenceId: json['razorpay_order_id'] as String?,
  providerPaymentId: json['razorpay_payment_id'] as String?,
  stripeCheckoutSessionId: json['stripe_checkout_session_id'] as String?,
  stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
  checkoutUrl: json['checkout_url'] as String?,
  checkoutClientSecret: json['checkout_client_secret'] as String?,
  stripePublishableKey: json['stripe_publishable_key'] as String?,
  razorpayKeyId: json['razorpay_key_id'] as String?,
);

Map<String, dynamic> _$PaymentModelToJson(PaymentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking': instance.booking,
      'penalty': instance.penalty,
      'payment_type': instance.paymentType,
      'amount': instance.amount,
      'currency': instance.currency,
      'provider': instance.provider,
      'razorpay_order_id': instance.orderReferenceId,
      'razorpay_payment_id': instance.providerPaymentId,
      'stripe_checkout_session_id': instance.stripeCheckoutSessionId,
      'stripe_payment_intent_id': instance.stripePaymentIntentId,
      'status': instance.status,
      'created_at': instance.createdAt,
      'checkout_url': instance.checkoutUrl,
      'checkout_client_secret': instance.checkoutClientSecret,
      'stripe_publishable_key': instance.stripePublishableKey,
      'razorpay_key_id': instance.razorpayKeyId,
    };
