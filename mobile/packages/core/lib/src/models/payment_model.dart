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
  final String currency;
  final String provider;
  @JsonKey(name: 'razorpay_order_id')
  final String? orderReferenceId;
  @JsonKey(name: 'razorpay_payment_id')
  final String? providerPaymentId;
  @JsonKey(name: 'stripe_checkout_session_id')
  final String? stripeCheckoutSessionId;
  @JsonKey(name: 'stripe_payment_intent_id')
  final String? stripePaymentIntentId;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'checkout_url')
  final String? checkoutUrl;
  @JsonKey(name: 'checkout_client_secret')
  final String? checkoutClientSecret;
  @JsonKey(name: 'stripe_publishable_key')
  final String? stripePublishableKey;

  const PaymentModel({
    required this.id,
    this.booking,
    this.penalty,
    required this.paymentType,
    required this.amount,
    required this.currency,
    required this.provider,
    this.orderReferenceId,
    this.providerPaymentId,
    this.stripeCheckoutSessionId,
    this.stripePaymentIntentId,
    required this.status,
    required this.createdAt,
    this.checkoutUrl,
    this.checkoutClientSecret,
    this.stripePublishableKey,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);
}
