"""
Test script to simulate Stripe webhook for payment verification.
This helps test the webhook flow without needing Stripe CLI.
"""
import requests
import json

# Get the checkout session ID from the most recent payment
# You'll need to replace this with the actual session ID from your payment

def test_webhook(checkout_session_id):
    """Simulate a checkout.session.completed webhook event"""
    
    webhook_url = "http://localhost:8000/api/v1/payments/webhook/"
    
    # Simulate Stripe webhook payload
    webhook_payload = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": checkout_session_id,
                "payment_status": "paid",
                "payment_intent": "pi_test_123456789",
                "customer_email": "test@example.com"
            }
        }
    }
    
    headers = {
        "Content-Type": "application/json",
        "Stripe-Signature": "test_signature"  # Will be ignored in dev mode
    }
    
    print(f"Sending webhook for session: {checkout_session_id}")
    response = requests.post(
        webhook_url,
        data=json.dumps(webhook_payload),
        headers=headers
    )
    
    print(f"Response status: {response.status_code}")
    print(f"Response body: {response.text}")
    
    if response.status_code == 200:
        print("✅ Webhook processed successfully!")
        print("The booking should now be CONFIRMED")
    else:
        print("❌ Webhook failed")

if __name__ == "__main__":
    # Replace with your actual checkout session ID from the payment
    session_id = input("Enter the Stripe checkout session ID: ")
    test_webhook(session_id)
