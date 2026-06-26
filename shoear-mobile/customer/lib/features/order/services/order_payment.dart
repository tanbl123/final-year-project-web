import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

import 'package:customer/features/order/services/order_service.dart';

/// Outcome of running the Stripe payment sheet for an order.
enum PayResult { paid, cancelled }

/// Runs the Stripe payment sheet for an existing (Placed) order: starts a
/// PaymentIntent, presents the branded sheet, and finalises the payment.
///
/// - Returns [PayResult.paid] on success, [PayResult.cancelled] if the user
///   dismisses the sheet.
/// - Throws [ApiException] for anything else (e.g. the order expired or an item
///   went out of stock — surfaced by createPaymentIntent), so callers can show
///   the server's message.
Future<PayResult> payOrderWithStripe(OrderService orders, String orderId) async {
  // May throw (ORDER_EXPIRED / OUT_OF_STOCK) BEFORE any card is charged.
  final pi = await orders.createPaymentIntent(orderId);

  Stripe.publishableKey = pi['publishableKey'] as String? ?? '';
  await Stripe.instance.applySettings();
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: pi['clientSecret'] as String,
      merchantDisplayName: 'ShoeAR',
      appearance: const PaymentSheetAppearance(
        colors: PaymentSheetAppearanceColors(primary: Color(0xFF4F46E5)),
        shapes: PaymentSheetShape(borderRadius: 12),
      ),
      billingDetailsCollectionConfiguration:
          const BillingDetailsCollectionConfiguration(
        address: AddressCollectionMode.never,
      ),
    ),
  );

  try {
    await Stripe.instance.presentPaymentSheet();
  } on StripeException {
    return PayResult.cancelled; // user dismissed the sheet
  }

  await orders.pay(orderId, 'Stripe',
      paymentIntentId: pi['paymentIntentId'] as String?);
  return PayResult.paid;
}
