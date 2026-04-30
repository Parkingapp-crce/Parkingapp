# Payment Testing Guide

## Current Setup

The payment system is now configured to work WITHOUT webhook signature verification in development mode. This means:

✅ Backend accepts webhooks without Stripe CLI
✅ Manual payment verification works
✅ Payments can be tested immediately

## How to Test Payment Flow

### Step 1: Create a Booking
1. Open user app at http://localhost:XXXX (check your Flutter output)
2. Search for a society
3. Select a parking slot
4. Create a booking
5. Booking will be in "PENDING PAYMENT" status

### Step 2: Initiate Payment
1. Click "Pay Now" button
2. Stripe checkout opens in new tab
3. Use test card: `4242 4242 4242 4242`
4. Any future expiry date (e.g., 12/34)
5. Any 3-digit CVC (e.g., 123)
6. Complete payment

### Step 3: Verify Payment
After completing payment, you have TWO options:

#### Option A: Automatic (Already Implemented)
1. Return to the original Flutter app tab
2. Pull down to refresh the booking detail screen
3. The app will call `/api/v1/payments/verify/` with the session ID
4. Booking should change to "CONFIRMED"

#### Option B: Manual Webhook Simulation (If automatic doesn't work)
1. Copy the checkout session ID from the URL (starts with `cs_test_`)
2. Run the test script:
   ```bash
   cd backend
   .\.venv\Scripts\Activate.ps1
   python ../test_webhook.py
   ```
3. Paste the session ID when prompted
4. Script will send webhook to backend
5. Booking should be confirmed

## What Happens Behind the Scenes

1. **Payment Initiation** (`POST /api/v1/payments/initiate/`)
   - Creates Payment record with status "PENDING"
   - Creates Stripe checkout session
   - Returns checkout URL

2. **User Completes Payment** (on Stripe)
   - User enters card details
   - Stripe processes payment
   - Redirects back with session ID in URL

3. **Payment Verification** (`POST /api/v1/payments/verify/`)
   - App sends checkout session ID to backend
   - Backend calls Stripe API to verify payment status
   - If paid: Updates Payment to "CAPTURED"
   - If paid: Updates Booking to "CONFIRMED"
   - If paid: Updates Slot to "RESERVED"

## Troubleshooting

### Payment stays in PENDING_PAYMENT
**Check:**
1. Did you complete the payment on Stripe?
2. Did you refresh the booking detail screen?
3. Check backend logs for errors

**Solution:**
- Pull down to refresh on booking detail screen
- Or use manual webhook simulation script

### "Payment not found" error
**Cause:** Session ID doesn't match any payment in database

**Solution:**
- Make sure you're using the correct session ID
- Check that payment was created (check backend logs)

### "Payment does not belong to this user" error
**Cause:** Trying to verify someone else's payment

**Solution:**
- Make sure you're logged in as the user who created the booking

## Backend Logs to Watch

When payment is verified, you should see:
```
[timestamp] "POST /api/v1/payments/verify/ HTTP/1.1" 200
```

When booking is confirmed, the booking status changes from:
- `PENDING_PAYMENT` → `CONFIRMED`

And slot state changes from:
- `AVAILABLE` → `RESERVED`

## Test Cards

Use these Stripe test cards:

| Card Number | Description |
|-------------|-------------|
| 4242 4242 4242 4242 | Successful payment |
| 4000 0000 0000 0002 | Card declined |
| 4000 0000 0000 9995 | Insufficient funds |

All test cards:
- Expiry: Any future date
- CVC: Any 3 digits
- ZIP: Any 5 digits

## Production Setup

For production, you MUST:
1. Set `STRIPE_WEBHOOK_SECRET` in `.env`
2. Configure webhook in Stripe Dashboard
3. Remove the insecure fallback in `services.py`

The current setup skips signature verification for development only.
