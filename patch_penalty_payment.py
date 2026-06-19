import re

filepath = 'mobile/apps/user_app/lib/screens/booking_detail_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

bypass_logic_old = """    if (payment.status == 'captured') {
      await context.read<BookingDetailCubit>().loadBooking(widget.bookingId);
      if (!mounted) return;
      context.read<PenaltiesCubit>().load(status: 'unpaid');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment bypass successful. Penalty paid.'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }"""

bypass_logic_new = """    if (payment.status == 'captured' && (payment.stripeCheckoutSessionId?.startsWith('bypass') == true || payment.razorpayOrderId?.startsWith('bypass') == true)) {
      if (!mounted) return;
      
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MockPaymentScreen(
            amount: penalty.amount,
            gateway: gateway,
          ),
        ),
      );
      
      if (success == true) {
        await context.read<BookingDetailCubit>().loadBooking(widget.bookingId);
        if (!mounted) return;
        context.read<PenaltiesCubit>().load(status: 'unpaid');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Penalty paid.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    }"""

content = content.replace(bypass_logic_old, bypass_logic_new)

with open(filepath, 'w') as f:
    f.write(content)

