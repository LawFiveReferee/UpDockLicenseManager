# UpDock License Manager

## v1.0.85 — Subscriber Marketing List
- Bumped app version to 1.0.85 build 90.
- Marketing settings now maintain separate Pro Purchasers and Subscribers lists.
- Refresh now imports opted-in Pro purchasers from licenses and website subscribers from the protected server endpoint.

## v1.0.84 — Marketing Table Width
- Bumped app version to 1.0.84 build 89.
- Marketing contacts now show a clearer opted-in contact count below the heading.
- Removed the Opt-ins column and changed Last Purchase to a compact date-only format.

## v1.0.83 — Marketing Contact Identity
- Bumped app version to 1.0.83 build 88.
- Marketing contacts now use name plus email as the unique row identity, allowing personalized entries for separate opted-in purchases that share an email address.
- Deleting a Marketing contact now clears consent only for matching name/email licenses.

## v1.0.82 — Marketing Opt-In Counts
- Bumped app version to 1.0.82 build 87.
- Marketing contacts now show how many opted-in purchases contributed to each unique email row.
- Marketing contact copy remains tab-separated `Name<TAB>Email` text.

## v1.0.81 — Marketing Contact Updates
- Bumped app version to 1.0.81 build 86.
- Marketing contacts now visibly update existing email rows when a newer opted-in purchase is imported.
- Added a Last Purchase column and refresh status that reports added and updated marketing contacts.

## v1.0.80 — Marketing Consent Visibility
- Bumped app version to 1.0.80 build 85.
- License detail now shows the imported marketing-updates consent value for web purchases.
- App-generated license emails now include the marketing-updates consent value.

## v1.0.79 — Marketing Store Test Contact
- Bumped app version to 1.0.79 build 84.
- Added a hidden development-only Marketing tab button for inserting a sample contact into the persistent marketing contact store.

## v1.0.78 — Persistent Marketing Contacts
- Bumped app version to 1.0.78 build 83.
- Marketing contacts are now saved in their own persistent contact store.
- Server sync and Marketing refresh now merge opted-in purchasers into the contact list instead of rebuilding it from the current license list.

## v1.0.77 — Shared License Store
- Bumped app version to 1.0.77 build 82.
- Settings and the main window now share the same `LicenseStore` instance.
- Fixed Marketing contacts losing previous entries when the Settings store showed or saved stale license data.

## v1.0.76 — Marketing Contacts Table
- Bumped app version to 1.0.76 build 81.
- Reworked Marketing contacts into a table-style view with row checkboxes and a header select-all checkbox.
- Added bottom action placement for Refresh, Delete, Copy Selected, and Copy All.

## v1.0.75 — Remove Legacy Simulation URL
- Bumped app version to 1.0.75 build 80.
- Removed unused network URL helpers for the retired public `simulate.php` endpoint.

## v1.0.74 — Marketing Contact Copy
- Bumped app version to 1.0.74 build 79.
- Marketing contacts can now be selected and copied, or copied all at once.
- Marketing contact copy now uses tab-separated `Name<TAB>Email` rows.

## v1.0.73 — Marketing Consent Contacts
- Bumped app version to 1.0.73 build 78.
- Synced Paddle marketing consent into license records for auto-fulfilled and manually fulfilled purchases.
- Added a Marketing settings tab that lists opted-in purchaser contacts and copies them as CSV.

## v1.0.72 — Launch Checklist Discount Wording
- Bumped app version to 1.0.72 build 77.
- Updated the launch checklist wording to cover live discounted checkout testing rather than only 100% discount codes.

## v1.0.71 — Marketing Discount Codes
- Bumped app version to 1.0.71 build 76.
- Reworked Paddle discount code generation as a marketing tool instead of a development-only test tool.
- Added percentage or dollar amount discounts, configurable usage limits, and an explicit optional product/price restriction list.

## v1.0.70 — Paddle Test Discount Codes
- Bumped app version to 1.0.70 build 75.
- Added a development-only Paddle settings tool that creates one-use 100% discount codes through the Paddle Discounts API.
- Generated codes are restricted to configured UpDock Pro price IDs and stored locally for copying.

## v1.0.69 — Development Tools Gate
- Bumped app version to 1.0.69 build 74.
- Added a General setting to show or hide development tools.
- Hidden by default: Signing Test, Development toolbar menu, column width readout, Pending Purchases developer actions, Server Email Test, and Activation Test.

## v1.0.68 — Automatic Server Sync
- Bumped app version to 1.0.68 build 73.
- Server-delivered licenses now sync automatically on app launch and when the app becomes active.
- Automatic sync runs silently and de-duplicates by serial; the toolbar sync button still shows an import result.

## v1.0.67 — Server License Sync
- Bumped app version to 1.0.67 build 72.
- Added a main toolbar action to sync server-delivered licenses into the local license list.
- Imported server licenses are de-duplicated by serial number and marked as email sent, fulfilled, and activation registered when appropriate.

## v1.0.66 — Server Delivered License Visibility
- Bumped app version to 1.0.66 build 71.
- Server Operations now shows delivered-license counts, latest delivered license files, and delivered-license storage status.
- Connection checks now display delivered-license and auto-fulfillment readiness flags returned by the server health endpoint.

## v1.0.65 — Email Card Placement
- Bumped app version to 1.0.65 build 70.
- Moved the Email Delivery card directly below Workflow Diagnostics in the license detail column.

## v1.0.64 — Server Email Test
- Bumped app version to 1.0.64 build 69.
- Added a Server Settings action that sends a fake license attachment through the protected server email test endpoint.
- The test uses the configured customer service email and does not create or fulfill a real license.

## v1.0.63 — Server Signing Export
- Bumped app version to 1.0.63 build 68.
- Added a guarded Signing settings action that copies the private signing key as a PHP config line for server-side auto-fulfillment.
- The private key is not displayed in the UI and the action includes a confirmation warning.

## v1.0.62 — Launch Checklist
- Bumped app version to 1.0.62 build 67.
- Added a Launch settings tab with automatic checks for live Paddle, server, manager token, and email sender configuration.
- Added persistent manual launch confirmations for Paddle approval, deployment, webhook scope, live checkout, pending purchase, fulfillment, and email draft verification.
- Added a Copy Launch Checklist Summary action for launch review notes.

## v1.0.61 — Email Test Draft
- Bumped app version to 1.0.61 build 66.
- Added a Prepare Test Draft action in Email settings to verify the Apple Mail sender, signature links, and attachment handling without fulfilling a purchase.
- Test drafts use an internal recipient and a fake do-not-use attachment instead of creating a real license.

## v1.0.60 — Mail Signature Suppression
- Bumped app version to 1.0.60 build 65.
- Apple Mail draft creation now suppresses Mail's default account signature so only the UpDock license email signature appears.

## v1.0.59 — Mail Draft Creation
- Bumped app version to 1.0.59 build 64.
- Preferred-sender email drafts now create the Apple Mail message directly so the saved From account is applied at draft creation.
- Plain-text Mail drafts now include visible download, customer service, and UpDock Pro URLs when using the AppleScript sender path.

## v1.0.58 — Mail Sender Matching
- Bumped app version to 1.0.58 build 63.
- Mail sender automation now waits for the compose draft and matches the preferred sender against configured Mail account addresses.
- Sender selection now uses Mail's account display format when a matching address is found.

## v1.0.57 — Mail Automation Permission
- Bumped app version to 1.0.57 build 62.
- Added the Mail-specific Apple Events sandbox exception for preferred sender selection.
- Updated the Apple Events permission description to mention the customer service sender account.

## v1.0.56 — Mail Sender Selection
- Bumped app version to 1.0.56 build 61.
- Email draft creation now asks Apple Mail to use the saved Preferred From Account when possible.
- Added the macOS Apple Events entitlement needed for Mail draft sender automation.

## v1.0.55 — License Email Install Links
- Bumped app version to 1.0.55 build 60.
- Added an UpDock Pro App Download link above the license registration instructions in customer email drafts.
- Updated the registration instructions and added extra spacing between signature links.

## v1.0.54 — Linked Mail Signature
- Bumped app version to 1.0.54 build 59.
- License email drafts now use rich text so the customer service and UpDock Pro signature lines are clickable links in Mail.
- Email settings now focus on the customer service email and UpDock Pro URL used by those signature links.

## v1.0.53 — Email Draft Settings
- Bumped app version to 1.0.53 build 58.
- Replaced the placeholder Email settings tab with editable Mail draft and signature settings.
- License email drafts now use the saved signature name, customer service email, and UpDock Pro URL.

## v1.0.52 — License Email References
- Bumped app version to 1.0.52 build 57.
- Customer license email drafts now include the license issued date and Paddle customer ID when available.
- Updated the email signature to use UpDock Customer Service, the customer service email address, and the UpDock Pro page link.

## v1.0.51 — Detail Version Label
- Bumped app version to 1.0.51 build 56.
- Added a small selectable version/build label below the main dashboard title.
- Added the same version/build label below the License header in the detail column.

## v1.0.50 — Development License Cleanup
- Bumped app version to 1.0.50 build 55.
- Added a Development toolbar menu with a confirmed Remove All Local Licenses action.
- The cleanup removes only local app license records and leaves Paddle, web fulfillment archives, and activation records untouched.

## v1.0.49 — Toolbar Priority Order
- Bumped app version to 1.0.49 build 54.
- Moved Settings and Signing Test into the first main toolbar group.
- Settings now appears before Signing Test so Sort and Export are more likely to collapse first on narrow windows.

## v1.0.48 — Adaptive Detail Layout
- Bumped app version to 1.0.48 build 53.
- Restored the selectable bottom-right main column width readout.
- Dashboard cards in the detail area now wrap as the detail column narrows.
- The newest license card now expands to the available detail width.
- The sidebar automatically hides when the window is too narrow for all three minimum columns.

## v1.0.47 — Main Column Width Defaults
- Bumped app version to 1.0.47 build 52.
- Set main window minimum column widths to Sidebar 200, List 325, and Detail 500.
- Set main window default column widths to Sidebar 225, List 375, and Detail 726, with maximum width left unconstrained.
- Removed the temporary bottom-right column width readout.

## v1.0.46 — Main Column Width Readout
- Bumped app version to 1.0.46 build 51.
- Added a selectable bottom-right readout showing the current Sidebar, List, and Detail column widths.
- The readout updates as the main window split-view columns are resized.

## v1.0.45 — Toolbar Label Preference
- Bumped app version to 1.0.45 build 50.
- Added a General setting to show text labels in the main toolbar.
- Main toolbar buttons now show hover help labels when rendered icon-only.

## v1.0.44 — Verified Paddle Secret Saves
- Bumped app version to 1.0.44 build 49.
- Paddle Settings now verifies Keychain writes before reporting API key or notification secret saves as successful.
- Added explicit sandbox and Keychain entitlements for the app target.

## v1.0.43 — Paddle Secret Blank Save Guard
- Bumped app version to 1.0.43 build 48.
- Paddle Settings no longer lets blank API key or notification secret field states overwrite saved Keychain values.
- Save actions now trim values before storing them and report when a blank secret was not saved.

## v1.0.42 — Paddle API Placeholder Guard
- Bumped app version to 1.0.42 build 47.
- The Keychain settings store now rejects the retired test_api_key_123 Paddle API placeholder globally.
- Reading an old placeholder from Keychain removes it immediately so Paddle Settings opens with an empty API key instead of the test value.

## v1.0.41 — Paddle Secret Persistence
- Bumped app version to 1.0.41 build 46.
- Paddle Settings now saves API key and webhook secret edits immediately.
- The old test_api_key_123 placeholder is cleared from Keychain if encountered.

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
