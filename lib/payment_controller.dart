import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_apple_pay/utils.dart';
import 'package:http/http.dart' as http;

class PaymentController {
// ===========================================================================
  // Apple Pay
  // ===========================================================================
  Future<bool?> payWithApplePay() async {
    // Total Price
    double totalPrice = 50;
    try {
      // Presenting apple payment sheet
      await Stripe.instance.presentApplePay(
        params: ApplePayPresentParams(
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: 'Item',
              amount: totalPrice.toString(),
            ),
          ],
          country: 'US',
          currency: 'EUR',
        ),
      );
      // Creating a payment intent, this will be used to get the client secret
      final paymentIntentResponse = await _getPaymentIntent({
        'amount': (totalPrice * 100).toInt().toString(),
        'currency': 'EUR',
        'payment_method_types[]': 'card',
      });
      //client secret
      final clientSecret = paymentIntentResponse!['client_secret'];
      // Confirm apple pay payment with the client secret
      await Stripe.instance.confirmApplePayPayment(clientSecret);
      log('Payment Successful');
      return true;
    } on PlatformException catch (exception) {
      log(exception.message ?? 'Something went wrong');
    } catch (exception) {
      log(exception.toString());
      return false;
    }
    return false;
  }

  // ===========================================================================
  // Creating a payment intent
  // ===========================================================================
  Future<Map<String, dynamic>?> _getPaymentIntent(
      Map<String, dynamic> data) async {
    try {
      http.Response paymentIntentRespose = await http.post(
        Uri.parse(
            '$stripeBaseURL/$createPaymentIntentURL?amount=${data['amount']}&currency=${data['currency']}&payment_method_types[]=${data['payment_method_types[]']}'),
        headers: <String, String>{
          'Authorization': 'Bearer $stripeSecretKey',
        },
      );
      var jsonData = jsonDecode(paymentIntentRespose.body);
      return jsonData;
    } catch (exception) {
      log(exception.toString());
    }
    return null;
  }
}
