# Stripe Webhook Configuration Guide

## Overview
Your backend has a complete Stripe webhook handler at `/api/v1/payments/webhook/` that automatically verifies payments and confirms bookings when Stripe sends payment events.

## Current Status
- ✅ Backend webhook endpoint: `http://localhost:8000/api/v1/payments/webhook/`
- ✅ Stripe credentials configured in `.env`
- ❌ Webhook secret not configured (STRIPE_WEBHOOK_SECRET is empty)
- ❌ Webhook not registered in Stripe Dashboard

## Setup Instructions

### Option 1: Using Stripe CLI (Recommended for Local Development)

1. **Install Stripe CLI**
   ```bash
   # Windows (using Scoop)
   scoop install stripe
   
   # Or download from: https://stripe.com/docs/stripe-cli
   ```

2. **Login to Stripe**
   ```bash
   stripe login
   ```

3. **Forward webhook events to your local server**
   ```bash
   stripe listen --forward-to http://localhost:8000/api/v1/payments/webhook/
   ```
   
   This will output a webhook signing secret like:
   ```
> Ready! Your webhook signing secret is <your_webhook_signing_secret>
   ```

4. **Copy the webhook secret to your `.env` file**
   ```env
STRIPE_WEBHOOK_SECRET=<your_webhook_signing_secret>
   ```

5. **Restart your Django server** to load the new secret

6. **Test the webhook**
   ```bash
   stripe trigger checkout.session.completed
   ```

### Option 2: Using ngrok (For Testing with Real Stripe Dashboard)

1. **Install ngrok**
   ```bash
   # Download from: https://ngrok.com/download
   ```

2. **Start ngrok tunnel**
   ```bash
   ngrok http 8000
   ```
   
   This will give you a public URL like: `https://abc123.ngrok.io`

3. **Configure webhook in Stripe Dashboard**
   - Go to: https://dashboard.stripe.com/test/webhooks
   - Click "Add endpoint"
   - Endpoint URL: `https://abc123.ngrok.io/api/v1/payments/webhook/`
   - Select events to listen to:
     - `checkout.session.completed`
     - `payment_intent.payment_failed`
   - Click "Add endpoint"

4. **Copy the webhook signing secret**
   - After creating the endpoint, click on it
   - Click "Reveal" under "Signing secret"
- Copy the webhook signing secret from Stripe

5. **Add to `.env` file**
   ```env
STRIPE_WEBHOOK_SECRET=<your_webhook_signing_secret>
   ```

6. **Restart your Django server**

## How It Works

1. **User initiates payment** → Backend creates Stripe checkout session
2. **User completes payment** → Stripe redirects back to app
3. **Stripe sends webhook** → `checkout.session.completed` event
4. **Backend receives webhook** → Verifies signature and processes payment
5. **Booking confirmed** → Status changes from `PENDING_PAYMENT` to `CONFIRMED`
6. **Slot reserved** → Slot state changes to `RESERVED`

## Events Handled

- `checkout.session.completed` - Payment successful, booking confirmed
- `payment_intent.payment_failed` - Payment failed, booking remains pending

## Testing

After configuring the webhook:

1. Start backend: `python manage.py runserver`
2. Start user app: `flutter run -d chrome`
3. Create a booking
4. Click "Pay Now"
5. Complete payment using test card: `4242 4242 4242 4242`
6. Webhook should automatically confirm the booking
7. Check backend logs for webhook processing

## Troubleshooting

### Webhook not receiving events
- Check that STRIPE_WEBHOOK_SECRET is set in .env
- Restart Django server after changing .env
- Check ngrok/Stripe CLI is running
- Verify endpoint URL is correct in Stripe Dashboard

### Signature verification fails
- Make sure you copied the correct webhook secret
- Don't use the same secret for test and live mode
- Restart server after updating .env

### Booking not confirming
- Check backend logs for errors
- Verify webhook event type is `checkout.session.completed`
- Check that booking exists and is in PENDING_PAYMENT status

## Current Configuration

Your `.env` file currently has:
```env
STRIPE_PUBLISHABLE_KEY=<your_stripe_publishable_key>
STRIPE_SECRET_KEY=<your_stripe_secret_key>
STRIPE_WEBHOOK_SECRET=  # ← ADD YOUR WEBHOOK SECRET HERE
```

## Next Steps

1. Choose Option 1 (Stripe CLI) or Option 2 (ngrok)
2. Follow the setup instructions
3. Add webhook secret to `.env`
4. Restart backend
5. Test payment flow
