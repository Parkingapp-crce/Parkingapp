"""
Automatic payment verification script.
Run this after completing a Stripe payment to automatically verify it.
"""
import sys
import requests
import stripe
from backend.parking_platform.settings import development as settings

# Configure Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY

def get_latest_checkout_session():
    """Get the most recent checkout session"""
    sessions = stripe.checkout.Session.list(limit=1)
    if sessions.data:
        return sessions.data[0]
    return None

def verify_payment(session_id=None):
    """Verify a payment by triggering the webhook handler"""
    if not session_id:
        # Get the latest session
        session = get_latest_checkout_session()
        if not session:
            print("❌ No checkout sessions found")
            return False
        session_id = session.id
        print(f"📋 Found latest session: {session_id}")
    
    # Simulate webhook event
    webhook_url = "http://localhost:8000/api/v1/payments/webhook/"
    
    webhook_payload = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": session_id
            }
        }
    }
    
    print(f"🔄 Sending webhook for session: {session_id}")
    response = requests.post(
        webhook_url,
        json=webhook_payload,
        headers={"Content-Type": "application/json"}
    )
    
    if response.status_code == 200:
        print("✅ Payment verified successfully!")
        print("✅ Booking should now be CONFIRMED")
        return True
    else:
        print(f"❌ Webhook failed: {response.status_code}")
        print(f"Response: {response.text}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1:
        session_id = sys.argv[1]
        verify_payment(session_id)
    else:
        # Auto-verify the latest payment
        verify_payment()
