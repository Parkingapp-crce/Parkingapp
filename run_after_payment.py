"""
Run this script AFTER completing a Stripe payment.
It will automatically verify the payment and confirm the booking.
"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, 'backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'parking_platform.settings.development')
django.setup()

import stripe
from django.conf import settings
from apps.payments.services import verify_checkout_session

# Configure Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY

def auto_verify_latest_payment():
    """Automatically verify the most recent payment"""
    print("🔍 Looking for recent checkout sessions...")
    
    # Get the most recent checkout session
    sessions = stripe.checkout.Session.list(limit=5)
    
    if not sessions.data:
        print("❌ No checkout sessions found")
        return
    
    print(f"📋 Found {len(sessions.data)} recent sessions")
    
    for session in sessions.data:
        print(f"\n Session ID: {session.id}")
        print(f"   Status: {session.payment_status}")
        print(f"   Amount: {session.amount_total / 100} {session.currency.upper()}")
        
        if session.payment_status == 'paid':
            print(f"   ✅ Payment completed - verifying...")
            try:
                payment = verify_checkout_session(session.id)
                print(f"   ✅ Payment verified successfully!")
                print(f"   ✅ Booking {payment.booking.booking_number} is now CONFIRMED")
                print(f"   ✅ Slot {payment.booking.slot.slot_number} is now RESERVED")
                return
            except Exception as e:
                print(f"   ❌ Verification failed: {e}")
        else:
            print(f"   ⏳ Payment not completed yet")
    
    print("\n❌ No paid sessions found to verify")

if __name__ == "__main__":
    auto_verify_latest_payment()
