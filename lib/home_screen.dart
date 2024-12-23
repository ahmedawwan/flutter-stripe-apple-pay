import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_apple_pay/payment_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Init State
  @override
  void initState() {
    Stripe.instance.isPlatformPaySupportedListenable.addListener(update);
    super.initState();
  }

  // Dispose
  @override
  void dispose() {
    Stripe.instance.isPlatformPaySupportedListenable.removeListener(update);
    super.dispose();
  }

  // Update
  void update() => setState(() {});

  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: PlatformPayButton(
            onPressed: () => _handleApplePayPress(context),
          ),
        ),
      ),
    );
  }

  // Apple Pay OnPressed Method
  void _handleApplePayPress(context) async {
    try {
      final bool isEnable = await Stripe.instance.isPlatformPaySupported();
      if (isEnable) {
        bool paymentSuccessful =
            await PaymentController().payWithApplePay() ?? false;
        if (paymentSuccessful) {
          // If payment is successful then execute this code
          log('payment successful');
        } else {
          // if payment failed
          log('payment failed');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Apple pay is not supported in this device'),
        ));
      }
    } catch (exception) {
      log(exception.toString());
    }
  }
}
