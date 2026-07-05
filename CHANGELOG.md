# UpDock License Manager

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
