import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_apple_pay/utils.dart';
import 'package:http/http.dart' as http;

class PaymentController {
  Future<bool?> payWithApplePay() async {
    // Total Price
    double totalPrice = 50;
    try {
      // Creating a payment intent, this will be used to get the client secret
      final paymentIntentResponse = await _getPaymentIntent({
        'amount': (totalPrice * 100).toInt().toString(),
        'currency': 'EUR',
        'payment_method_types[]': 'card',
      });
      log(paymentIntentResponse.toString());
      if (paymentIntentResponse == null) {
        throw Exception('Failed to create payment intent');
      }
      //client secret
      final String clientSecret = paymentIntentResponse['client_secret'];

      // Presenting apple payment sheet
      final PaymentIntent paymentIntent =
          await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'US',
            currencyCode: 'EUR',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: 'Item',
                amount: totalPrice.toString(),
              )
            ],
          ),
        ),
      );
      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        log('Payment Successful');
        return true;
      } else {
        throw Exception(paymentIntent.status);
      }
    } on PlatformException catch (exception) {
      log(exception.message ?? 'Something went wrong');
    } catch (exception) {
      log(exception.toString());
    }
    return false;
  }

  // Creating a payment intent
  Future<Map<String, dynamic>?> _getPaymentIntent(
      Map<String, dynamic> data) async {
    try {
      http.Response paymentIntentResponse = await http.post(
        Uri.parse(
            '$createPaymentIntentURL?amount=${data['amount']}&currency=${data['currency']}&payment_method_types[]=${data['payment_method_types[]']}'),
        headers: <String, String>{
          'Authorization': 'Bearer $stripeSecretKey',
        },
      );
      var jsonData = jsonDecode(paymentIntentResponse.body);
      return jsonData;
    } catch (exception) {
      log(exception.toString());
    }
    return null;
  }
}
