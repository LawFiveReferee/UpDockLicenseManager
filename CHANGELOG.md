# UpDock License Manager

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
