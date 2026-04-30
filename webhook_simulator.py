"""
Webhook simulator that monitors Stripe for completed payments
and automatically triggers verification.
"""
import time
import threading
import stripe
import requests
import json
import os
from datetime import datetime, timedelta

# Configure Stripe
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY", "")

class WebhookSimulator:
    def __init__(self):
        self.processed_sessions = set()
        self.running = False
        
    def start_monitoring(self):
        """Start monitoring for completed payments"""
        self.running = True
        print("🔄 Starting payment monitoring...")
        print("💡 Complete a payment on Stripe and it will be auto-verified!")
        
        while self.running:
            try:
                self.check_for_new_payments()
                time.sleep(2)  # Check every 2 seconds
            except KeyboardInterrupt:
                print("\n⏹️  Stopping monitor...")
                self.running = False
                break
            except Exception as e:
                print(f"❌ Error: {e}")
                time.sleep(5)
    
    def check_for_new_payments(self):
        """Check for new completed payments"""
        # Get recent sessions (last 10 minutes)
        created_after = int((datetime.now() - timedelta(minutes=10)).timestamp())
        
        sessions = stripe.checkout.Session.list(
            limit=10,
            created={'gte': created_after}
        )
        
        for session in sessions.data:
            if session.id not in self.processed_sessions and session.payment_status == 'paid':
                print(f"\n🎉 New payment detected!")
                print(f"   Session: {session.id}")
                print(f"   Amount: {session.amount_total / 100} {session.currency.upper()}")
                
                success = self.trigger_webhook(session.id)
                if success:
                    self.processed_sessions.add(session.id)
                    print(f"   ✅ Payment verified and booking confirmed!")
                else:
                    print(f"   ❌ Failed to verify payment")
    
    def trigger_webhook(self, session_id):
        """Trigger webhook for a completed session"""
        webhook_url = "http://localhost:8000/api/v1/payments/webhook/"
        
        payload = {
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "id": session_id
                }
            }
        }
        
        try:
            response = requests.post(
                webhook_url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            return response.status_code == 200
        except Exception as e:
            print(f"   ❌ Webhook failed: {e}")
            return False

if __name__ == "__main__":
    simulator = WebhookSimulator()
    try:
        simulator.start_monitoring()
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
