# UpDock License Manager

## v1.0.40 — Paddle Secret Save Consistency
- Bumped app version to 1.0.40 build 45.
- Paddle Settings now saves API key and webhook secret to Keychain before updating the local private config file.

## v1.0.39 — Checkout HTML Builder
- Bumped app version to 1.0.39 build 44.
- Paddle Settings now stores the Paddle client-side token.
- Added a Copy Checkout HTML action that builds the pro.html purchase block from the current Paddle environment and site-license pricing table.

## v1.0.38 — Webhook Log Export
- Bumped app version to 1.0.38 build 43.
- Webhook Log now has Copy Log and Export Text actions for sharing Paddle diagnostics.

## v1.0.37 — Pending Purchase Customer Display
- Bumped app version to 1.0.37 build 42.
- Pending Purchases now uses the normalized customer email and name fallback logic in the purchase list.

## v1.0.36 — Pending Purchase Environment Labels
- Bumped app version to 1.0.36 build 41.
- Pending Purchases now shows the Paddle environment for each transaction before fulfillment.
- Batch fulfillment summarizes selected transaction environments so mixed Sandbox and Production batches are visible.

## v1.0.35 — Paddle Environment Readiness
- Bumped app version to 1.0.35 build 40.
- Production Readiness now compares the app Paddle environment with the server Paddle API mode reported by health.php.
- The readiness check warns when the app is set to Sandbox but the server is Production, or the reverse.

## v1.0.34 — Paddle Private Config Updates
- Bumped app version to 1.0.34 build 39.
- Paddle Settings can now update PADDLE_API_KEY, PADDLE_WEBHOOK_SECRET, and PADDLE_API_BASE_URL in the local private paddle-config.php file.
- Local config updates reuse remembered file access and remind the operator to sync the private file separately.

## v1.0.33 — Production Readiness Panel
- Bumped app version to 1.0.33 build 38.
- Added a Production Readiness section to Server Settings.
- Readiness checks now cover signing, local secrets, private web config, server health, storage, operations, pending queue, webhook intake, and email draft handoff.

## v1.0.32 — Fulfillment Email Draft Option
- Bumped app version to 1.0.32 build 37.
- Pending Purchases now has a persistent option to prepare customer email drafts after fulfillment.
- Single and batch fulfillment status messages now report prepared, skipped, and failed email drafts.

## v1.0.31 — Copy Webhook Diagnostics
- Bumped app version to 1.0.31 build 36.
- Added a Copy Results button for Recent Webhook Events in Server Settings.
- Copied diagnostics include event message, status, time, and context fields.

## v1.0.30 — Webhook Event Diagnostics
- Bumped app version to 1.0.30 build 35.
- Server Settings now displays webhook event context such as Paddle status code, path, and sanitized error details.

## v1.0.29 — Remember Private Config Access
- Bumped app version to 1.0.29 build 34.
- Local private config updates now remember security-scoped access to the selected paddle-config.php file.
- Future Manager Token config updates reuse the saved file access unless the file moves or permission expires.

## v1.0.28 — Private Config File Picker
- Bumped app version to 1.0.28 build 33.
- Manager Token local config updates now use a file picker so the sandboxed app can write to the selected private paddle-config.php file.
- Added an Update Local Config action directly in Server Settings.

## v1.0.27 — Local Private Config Token Update
- Bumped app version to 1.0.27 build 32.
- Manager Token saved alert now includes an Update Local Config action.
- The action updates UPDOCK_MANAGER_TOKEN in the local private paddle-config.php file and reminds the operator to sync it separately.

## v1.0.26 — Manager Token Sync Reminder
- Bumped app version to 1.0.26 build 31.
- Generating or saving a Manager Token now shows a reminder to update and separately sync the private web config.
- Added a Copy Token action in the reminder so the private config can be updated without reselecting the field.

## v1.0.25 — Operations Token Fallback
- Bumped app version to 1.0.25 build 30.
- Refresh Operations now retries with the saved Keychain manager token if the visible Manager Token field returns HTTP 401.
- The Manager Token field is updated to the saved token when the fallback succeeds.

## v1.0.24 — Operations Token Handling
- Bumped app version to 1.0.24 build 29.
- Server Operations now uses the current Manager Token field value when building and fetching the operations-status URL.
- Refresh Operations saves the current Manager Token before making the request.

## v1.0.23 — Server Operations Summary
- Bumped app version to 1.0.23 build 28.
- Server Settings now fetches and displays operations-status counts inside the app.
- Added storage writability and recent webhook event summaries to Server Settings.

## v1.0.22 — Operations Status URL
- Bumped app version to 1.0.22 build 27.
- Server Settings now builds the authenticated operations-status URL from the saved base URL and manager token.
- Added a copy action for the operations-status URL.

## v1.0.21 — Email Sent Tracking
- Bumped app version to 1.0.21 build 26.
- Added a Sent email delivery state so prepared drafts and completed customer delivery are tracked separately.
- Added a Mark Sent action and audit event for customer license emails.
- Recovery Report and CSV export now include the customer email delivery state.

## v1.0.20 — Customer License Email Detail
- Bumped app version to 1.0.20 build 25.
- License email drafts now include serial number, seat allowance, and Paddle purchase reference when available.
- Site-license email subjects now identify the message as a site license.

## v1.0.19 — Activation Visibility
- Bumped app version to 1.0.19 build 24.
- Seat Usage and Activation Registry cards now appear for all commercial licenses.
- Non-site commercial licenses show activation registration as not required.

## v1.0.18 — Activation Registry Fulfillment
- Bumped app version to 1.0.18 build 23.
- Site-license fulfillment now registers the generated license serial and seat allowance with the activation registry.
- License details now show activation registry status for site licenses.
- Recovery Report and CSV export now include activation registry registration state.

## v1.0.17 — Activation Test Tools
- Bumped app version to 1.0.17 build 22.
- Added generated activation registry URLs to Server Settings.
- Added a one-button two-seat activation limit test.
- Server health now displays license and activation storage writability when available.

## v1.0.16 — Site License Seat Tracking
- Bumped app version to 1.0.16 build 21.
- Added seat allowance and assigned-seat tracking to license records.
- Site-license fulfillment now records purchased quantity as the seat allowance.
- Added editable Seat Usage details and recovery checks for seat overages.
- CSV license exports now include seat allowance and assigned-seat counts.

## v1.0.15 — Pricing Tier Paddle IDs
- Bumped app version to 1.0.15 build 20.
- Added editable Price ID and Product ID columns to the Site License Pricing table.
- Fulfillment policy matching now recognizes site-license IDs entered directly in pricing tiers.

## v1.0.14 — Site License Pricing Preview
- Bumped app version to 1.0.14 build 19.
- Pending purchase review now shows the matched site-license pricing tier for site-license purchases.
- License preview now shows discount, per-seat price, and expected total before fulfillment.

## v1.0.13 — Site License Pricing Table
- Bumped app version to 1.0.13 build 18.
- Added an editable Site License Pricing table in Paddle Settings.
- Added default tiers for 1-4 through 50+ seats with placeholder discounts and per-seat prices.
- Added a Restore Defaults action for the site-license pricing schedule.

## v1.0.12 — Paddle Fulfillment Policies
- Bumped app version to 1.0.12 build 17.
- Added Paddle fulfillment policy settings for site-license product and price IDs.
- Pending purchase review and preview now show whether a purchase will create individual seats or one site license.
- Fulfillment can now create a single commercial site-license record with the purchased quantity as the seat allowance.

## v1.0.11 — Seat Position Badges
- Bumped app version to 1.0.11 build 16.
- Changed multi-seat license row badges from total seat count to "Seat x of y".
- Added the same seat position label to Web Fulfillment details.
- Added badge support for future site-license records when product or notes identify a site license.

## v1.0.10 — Multi-Seat Visibility
- Bumped app version to 1.0.10 build 15.
- Added multi-seat badges to license rows when multiple licenses share a Paddle transaction.
- Added license count visibility to the Web Fulfillment detail section.
- Stopped flagging shared Paddle transaction IDs as recovery failures because they are valid for multi-seat purchases.

## v1.0.9 — Quantity Fulfillment
- Bumped app version to 1.0.9 build 14.
- Added Paddle quantity parsing for pending purchases.
- Fulfillment now creates one commercial license per purchased quantity while avoiding duplicates for already-created licenses.
- Pending purchase review and license preview now show quantity and generated license count.

## v1.0.8 — Pending License Preview
- Bumped app version to 1.0.8 build 13.
- Enabled the Pending Purchases Preview License action.
- Added a license preview sheet showing customer, product, Paddle, and fulfillment details before creating a commercial license.

## v1.0.7 — Paddle Customer Fallbacks
- Bumped app version to 1.0.7 build 12.
- Added cardholder name fallback for Paddle purchases when the customer record has no name.
- Fulfillment now uses the fallback name for commercial licenses created from Paddle purchases.

## v1.0.6 — Real Paddle Payloads
- Bumped app version to 1.0.6 build 11.
- Added parsing for product details from real Paddle transaction webhook payloads.
- Fulfillment now preserves product IDs from Paddle price metadata when product objects are absent.

## v1.0.5 — Webhook Diagnostics
- Bumped app version to 1.0.5 build 10.
- Added a Pending Purchases developer action for checking the protected Paddle webhook log.
- Added a Webhook Log viewer for stored, ignored, and failed webhook events.

## v1.0.4 — Actionable Recovery
- Bumped app version to 1.0.4 build 9.
- Added a Refresh Archive action to Recovery Report rows with unconfirmed web fulfillment archive status.
- Recovery Report rows now show per-action success or error feedback after refresh attempts.

## v1.0.3 — Recovery Export
- Bumped app version to 1.0.3 build 8.
- Added CSV export to the Recovery Report.
- Exported reports preserve grouped transaction, customer, license, failure, and warning context.

## v1.0.2 — Grouped Recovery Report
- Bumped app version to 1.0.2 build 7.
- Grouped Recovery Report rows by transaction, license, or customer so repeated issues appear under one record.
- Added affected transaction and customer counts to the Recovery Report summary.

## v1.0.1 — Recovery Report
- Bumped app version to 1.0.1 build 6.
- Added a Recovery Report window for scanning all licenses for workflow mismatches.
- Detects duplicate serials, duplicate Paddle transactions, missing Paddle IDs, unconfirmed archive status, missing or failed email draft readiness, Paddle email mismatches, and missing audit trails.
- Recovery issues can jump directly back to the affected license.

## v1.0.0 Beta — Workflow Diagnostics
- Bumped app version to 1.0.0 build 5.
- Added license-level workflow diagnostics for local license state, Paddle transaction linkage, web archive status, email draft readiness, and audit trail coverage.
- Added clear complete, warning, failed, and not-applicable states so operators can see what still needs attention before customer delivery.

## v0.9.9 — Fulfillment History
- Bumped app version to 0.9.9 build 4.
- Added a persistent audit log stored separately from the license database.
- Added an Audit Log window with search and JSON export.
- Added recent per-license history in the license detail view.
- Recorded audit events for creation, edits, deletion/restore, revocation, Paddle fulfillment, fulfillment checks, email draft attempts, and exports.

## v0.9.8 — Email Delivery
- Bumped app version to 0.9.8 build 3.
- Added persistent email delivery status to license records.
- Added a license detail Email Delivery card with Prepare Email and Retry Email actions.
- Added a Needs Email sidebar queue for licenses that still need email attention.
- Email retries reuse the existing license record and exported license file generation path instead of creating a new license.

## v0.9.7 — Batch Fulfillment
- Bumped app version to 0.9.7 build 2.
- Pending Purchases now supports multi-selection.
- Added sequential batch fulfillment with progress reporting.
- Added a batch review panel for selected purchases.
- Batch fulfillment creates licenses, archives transactions, refreshes the queue, and keeps failures visible.

## v0.9.6 — Workflow Polish
- Moved active development from ChatGPT handoff into Bitrig/GitHub.
- Cleaned repository metadata and ignored machine-local Finder/Xcode files.
- Pending Purchases now stays open after fulfillment, refreshes immediately, and selects the next purchase.
- Added in-app fulfillment status messages and duplicate local license protection.
- Added license detail web fulfillment archive status with refresh.
- Added Server Settings connection diagnostics for PHP health and writable backend folders.

## v0.9.0 — Connected System
* ✅ Manager token authentication
* ✅ Website integration
* ✅ Webhook simulator
* ✅ End-to-end queue working
* ✅ Pending purchases visible in the app
## v0.8.0
- Native Settings
* Keychain integration
* Server configuration
* Networking layer
* Pending Purchases window
* Pending queue retrieval
- Added generic networking layer
- Added Pending Purchases service
- Added authenticated pending URL generation
- Added server configuration page
- Added manager token generation and Keychain storage

## v0.7.6
- Added Server Settings page
- Added Keychain-backed Manager Token
- Added derived server URLs

## v0.7.5
- Added Paddle Notification Secret storage

...
