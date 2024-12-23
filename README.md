# flutter_stripe_apple_pay

Demonstration of Apple Pay with Stripe in a Flutter app using flutter_stripe package.

---

## Required Packages

<li>flutter_stripe</li>

Add flutter_stripe in your `pubspec.yaml`

```yaml
dependencies:
  flutter_stripe: 11.3.0
```

---

## iOS Integration

Compatible with apps targeting **iOS 12** or above.

## Set the stripe publishable key and merchant id in your main function

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'YOUR-STRIPE-PUBLISHABLE-KEY';
  Stripe.merchantIdentifier = 'YOUR-APPLE-MERCHANT-IDENTIFIER';
  Stripe.instance.applySettings();
  runApp(const MyApp());
}
```

Note: Make sure to use the correct capitalisation and spelling when entering the merchant identifier, as it is case sensitive.

---

## Implementing Apple Pay Flow

Before implementing the Apple Pay Flow, it is important to register a listener for the **isApplePaySupported** ValueListenable to ensure that the device supports Apple Pay.

```dart
 @override
  void initState() {
    Stripe.instance.isPlatformPaySupportedListenable.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    Stripe.instance.isPlatformPaySupportedListenable.removeListener(update);
    super.dispose();
  }

  void update() {
    setState(() {});
  }
```

---

## UI 

```dart
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
```

---

## Implementing the _handleApplePayPressMethod

Create this method in the UI file

```dart
void _handleApplePayPress(context) async {
    try {
      if (await Stripe.instance.isPlatformPaySupported()) {
        bool paymentSuccessful = await PaymentController().payWithApplePay() ?? false;
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
```

---

## Creating a PaymentController

We will first create a PaymentController class with a method payWithApplePay() that will handle the presentation of the Apple Pay sheet. Next, we will use the _getPaymentIntent() method to create a payment intent by calling the Stripe RESTful API. After this, we will retrieve the client_secret from the payment intent response and use it to confirm the Apple Pay payment.

```dart
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
```
