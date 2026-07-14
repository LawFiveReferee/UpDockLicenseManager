# UpDock Pro Live Purchase Workflow

This document describes the current live order workflow for UpDock Pro: what each system does, what data moves between systems, and what the customer experiences from purchase through app registration.

## System Roles

### Website

The public website at `updockapp.com` is the customer entry point.

- `pro.html` presents the UpDock Pro purchase page.
- The purchase sheet collects customer name, email address, license quantity, and UpDock-controlled marketing consent before opening Paddle checkout.
- The checkout button passes live Paddle client-side configuration, live price IDs, quantity, customer details, custom data, and the success URL into Paddle.
- `thanks.html` confirms the customer returned from checkout and displays purchase context such as name, email, reference time, quantity, estimated pricing, marketing consent, and Paddle transaction ID when available.
- The contact page supports mailing-list subscribe and unsubscribe flows.
- Public subscribe/unsubscribe endpoints store subscriber and unsubscribe records on the server.
- Protected server endpoints let the Purchase Manager app sync pending purchases, delivered licenses, marketing subscribers, unsubscribed emails, webhook logs, health status, and operations status.

The website also hosts the private fulfillment layer in `updock-private`, which must not be public or committed.

### Paddle

Paddle is the live payment processor and checkout system.

- Paddle hosts the checkout window and collects payment details.
- Paddle applies discount codes when the buyer enters a valid code.
- Paddle sends its own purchase confirmation or invoice email to the buyer.
- After payment completes, Paddle sends a `transaction.completed` webhook to the website server.
- The webhook payload includes transaction, customer, price, quantity, and custom data needed for fulfillment.
- Paddle remains the source of truth for payment status, transaction ID, customer ID, and invoice records.

### Website Server Fulfillment

The server receives Paddle webhooks and turns completed purchases into UpDock license deliveries.

- `paddle/webhook.php` verifies the Paddle webhook signature and stores the completed transaction.
- The private auto-fulfillment code reads the completed transaction and creates signed `.updocklicense` files when auto-fulfillment is enabled.
- The server sends the UpDock license email to the buyer with the license file attached.
- Delivered license metadata is stored in the private server storage area so the Purchase Manager app can sync it later.
- Fulfillment records, delivered licenses, activations, webhook logs, subscribers, and unsubscribed emails are stored as server-side files under the private storage area.
- The server health endpoint reports whether storage, signing, email, and auto-fulfillment prerequisites are available.

### Purchase Manager App

The UpDock Purchase Manager app is the operational console.

- It stores Paddle, server, signing, email, and marketing settings.
- It can manually fulfill pending purchases if auto-fulfillment is disabled or a transaction needs intervention.
- It syncs server-delivered licenses into the local license list.
- It displays workflow diagnostics for each license, including Paddle transaction linkage, email delivery state, server archive state, and activation registry state.
- It syncs Pro purchaser marketing opt-ins from licenses.
- It syncs website subscribers and unsubscribed emails from protected server endpoints.
- It can copy selected or all marketing addresses as tab-separated `Name<TAB>Email` text.
- It can generate Paddle discount codes using the live Paddle API.
- It provides troubleshooting views for webhook logs, health checks, pending purchases, delivered licenses, activation tests, and launch readiness.

The app is not the public customer-facing registration system; it is the internal management and recovery tool.

### UpDock Pro App

The UpDock Pro app is the customer-installed Mac app.

- The customer downloads and installs UpDock Pro after purchase.
- The customer imports the attached `.updocklicense` file in UpDock Pro Settings.
- UpDock Pro validates the signed license file.
- For site licenses, UpDock Pro uses the server activation registry to enforce the allowed seat count.
- Once registered, UpDock Pro unlocks the licensed Pro features for that Mac.

### Supabase

Supabase is not currently part of the live purchase fulfillment path.

The current system uses private server-side files for transactions, fulfilled records, delivered license metadata, activation records, subscriber records, and unsubscribe records. If Supabase is added later, it would most likely replace or mirror some of those private file stores, such as:

- delivered license registry
- activation registry
- marketing subscriber and unsubscribe lists
- fulfillment audit/history records
- operational dashboards or reporting

Until that migration happens, Supabase has no required role in live order processing.

## Customer Workflow

### 1. Customer Starts Purchase

The customer visits the UpDock Pro page on the website and clicks the purchase button.

The website opens an UpDock purchase sheet. The customer enters:

- name
- email address
- quantity
- optional marketing consent

The sheet then opens Paddle checkout with the configured live price ID for the selected quantity.

### 2. Customer Completes Paddle Checkout

In Paddle checkout, the customer:

- reviews the purchase
- optionally enters a discount code
- provides payment information
- completes the purchase

Paddle processes the payment and creates a live transaction.

### 3. Customer Reaches Thanks Page

After checkout, Paddle redirects the customer to the UpDock thanks page.

The thanks page shows the available purchase context, including:

- customer name
- email
- transaction ID when supplied
- quantity
- estimated price details
- marketing consent

The price information is an estimate and may not include taxes or discounts applied inside Paddle.

### 4. Paddle Sends Webhook

Paddle sends a `transaction.completed` webhook to the website server.

The server verifies the webhook, stores the transaction, and records the event in the webhook log.

### 5. Server Auto-Fulfills the Order

When auto-fulfillment is enabled and server health checks pass, the private fulfillment code:

- determines purchased quantity and license type
- creates one or more signed `.updocklicense` files
- stores delivered license metadata
- sends the UpDock license email to the buyer
- records the fulfillment result

For individual purchases, the buyer receives a single-seat commercial license. For site-license quantities, the buyer receives a site license with the configured seat allowance.

### 6. Customer Receives Emails

The customer receives two separate email streams:

- Paddle confirmation or invoice email from Paddle
- UpDock license email from UpDock customer service

The UpDock license email includes:

- attached `.updocklicense` file
- serial number
- issue date
- Paddle purchase reference
- Paddle customer ID when available
- seat allowance
- download link
- registration instructions
- customer service and UpDock Pro webpage links

### 7. Customer Downloads UpDock Pro

The customer downloads and installs UpDock Pro from the UpDock website.

The thanks page and license email should both guide the customer to the download location.

### 8. Customer Registers UpDock Pro

The customer opens UpDock Pro and imports the attached license file:

1. Open UpDock Pro.
2. Choose `Show UpDock Pro Settings…` from the UpDock menu.
3. Import the attached `.updocklicense` file.

UpDock Pro validates the license signature and unlocks Pro features. If the license is a site license, activation is checked against the server activation registry.

### 9. Purchase Manager Syncs the Result

The Purchase Manager app syncs server-delivered licenses automatically on launch and when it becomes frontmost. It can also be refreshed manually.

After sync, the order appears in the app license list with:

- customer name and email
- serial number
- issued date
- Paddle transaction ID
- Paddle customer ID
- license type
- seat allowance
- marketing consent
- workflow diagnostics

If a purchase was auto-fulfilled successfully, it should not remain in Pending Purchases.

### 10. Marketing Lists Update

If the buyer opted into UpDock marketing updates, the Purchase Manager can add the buyer to the Pro Purchasers marketing list.

Website subscriber signups appear in the Subscribers marketing list after refresh. Unsubscribes are synced from the server and suppress matching email addresses. A later explicit website signup clears that unsubscribe suppression.

## Operator Workflow

### Normal Live Order

For a normal auto-fulfilled purchase, the operator should see:

- Paddle transaction completed
- UpDock license email delivered
- no Pending Purchases entry
- delivered license count increases
- app license list updates after sync
- Pro Purchasers list updates if the buyer opted in

No manual action is required.

### Manual Recovery

If something fails, the Purchase Manager can be used to diagnose and recover.

Use these views first:

- Server Health
- Server Operations
- Webhook Log
- Pending Purchases
- License Workflow Diagnostics
- Activation Registry

Common recovery paths:

- If webhook arrived but auto-fulfillment did not run, inspect health and webhook log.
- If purchase is pending, manually fulfill it from Pending Purchases.
- If the license email did not send, regenerate or prepare an email from the app.
- If a delivered license did not appear locally, run server sync.
- If a site license activation fails, check activation registry status and seat allowance.

## Data and Identifier Flow

The Paddle transaction ID is the primary cross-system troubleshooting identifier.

It should appear in:

- Paddle transaction/invoice
- thanks page when available
- webhook log
- delivered license metadata
- Purchase Manager license detail
- UpDock license email

The Paddle customer ID is also stored when available and is useful for Paddle-side support and customer lookup.

## Launch Readiness Notes

Before opening purchases broadly:

- Confirm Paddle checkout uses live client-side token and live price IDs.
- Confirm server API mode is production.
- Confirm webhook destination is production and subscribed to the required event.
- Confirm private server config and signing key are present.
- Confirm server health is OK.
- Confirm auto-fulfillment is enabled.
- Confirm one live purchase completes end to end.
- Confirm subscriber and unsubscribe flows work.
- Confirm the privacy policy is live and linked.
- Back up private server storage regularly.

