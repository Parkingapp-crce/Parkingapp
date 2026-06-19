import re

filepath = 'mobile/apps/user_app/lib/screens/booking_detail_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Add the import
if "import 'mock_payment_screen.dart';" not in content:
    content = content.replace(
        "import 'package:lucide_icons/lucide_icons.dart';",
        "import 'package:lucide_icons/lucide_icons.dart';\nimport 'mock_payment_screen.dart';"
    )

# Replace the bypass logic in _initiatePayment
bypass_logic_old = """    // Bypass mode returns an already captured payment; treat it as immediate success.
    if (payment.status == 'captured') {
      await cubit.loadBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment bypass successful. Booking confirmed.'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }"""

bypass_logic_new = """    // Bypass mode returns an already captured payment.
    if (payment.status == 'captured' && (payment.stripeCheckoutSessionId?.startsWith('bypass') == true || payment.razorpayOrderId?.startsWith('bypass') == true)) {
      if (!mounted) return;
      
      // Navigate to our Mock Payment UI instead of skipping straight to success
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MockPaymentScreen(
            amount: booking.amount,
            gateway: gateway,
          ),
        ),
      );
      
      if (success == true) {
        await cubit.loadBooking(widget.bookingId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Booking confirmed.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    }"""

content = content.replace(bypass_logic_old, bypass_logic_new)

with open(filepath, 'w') as f:
    f.write(content)

