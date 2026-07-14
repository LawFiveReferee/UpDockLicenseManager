# UpDock Pro License File Format

## File Format

`.updocklicense` files are plain UTF-8 JSON files. They are not property lists, encoded JSON blobs, or package/document bundles.

The file contains a top-level wrapper object and a nested `license` payload object. The top-level `signature` signs only the canonical JSON encoding of the nested `license` object.

## Signature

Algorithm: Ed25519 using `CryptoKit.Curve25519.Signing`.

Signature field: top-level `signature`, Base64-encoded raw Ed25519 signature bytes.

Public key format for UpDock Pro: Base64-encoded raw Ed25519 public key bytes.

Public key:

```swift
enum UpDockLicensePublicKey {
  static let base64 = "3VgDz05u96lObK2Hhjp4FJG/Fn8K9hGSL/3RZPGTLuA="
}
```

## Canonical Payload Before Signing

Encode the nested `license` object with `JSONEncoder` using:

```swift
encoder.outputFormatting = [.sortedKeys]
encoder.dateEncodingStrategy = .iso8601
```

The exact canonical JSON for the sample file is:

```json
{"bundleID":"com.stockly.updockpro","customerID":"11111111-2222-4333-8444-555555555555","edition":"pro","email":"beta@example.com","expiresAt":"2026-10-31T23:59:59Z","formatVersion":2,"issuedAt":"2026-07-13T12:00:00Z","licenseKind":"beta","name":"Sample Beta Tester","product":"UpDock Pro","seatAllowance":3,"serial":"UPD-PRO-BETA-2026-SAMPLE-0001","type":"Beta"}
```

## Required Verification Checks in UpDock Pro

- Decode the file as plain JSON into the wrapper object.
- Confirm `fileType == "UpDockLicense"`.
- Confirm `signatureAlgorithm == "Ed25519"`.
- Re-encode `license` canonically with sorted keys and ISO-8601 dates.
- Verify the Base64 top-level signature against that canonical license data using the embedded public key.
- Confirm `license.bundleID == Bundle.main.bundleIdentifier` for the Pro build, expected `com.stockly.updockpro`.
- Confirm `license.edition == "pro"`.
- Confirm `license.licenseKind == "beta"` or `"paid"`.
- Confirm `license.expiresAt` is either missing for paid licenses or still in the future for beta licenses.

## Signed License Payload Fields

- `formatVersion`: currently `2`.
- `serial`: human-readable license serial.
- `type`: manager-facing type, currently `Beta`, `Trial`, or `Commercial`.
- `product`: currently `UpDock Pro`.
- `bundleID`: currently `com.stockly.updockpro`.
- `edition`: currently `pro`.
- `licenseKind`: app-facing kind, currently `beta`, `trial`, or `paid`.
- `customerID`: stable UUID from the License Manager license record.
- `seatAllowance`: intended Mac activation allowance for this license, currently defaulting to `3` in exported files.
- `name`: customer/tester name.
- `email`: customer/tester email.
- `issuedAt`: ISO-8601 issue date.
- `expiresAt`: ISO-8601 expiration date for beta/trial, absent/null for paid.
- `signature`: legacy nested field, currently omitted/null and not used. The real signature is top-level.

## Sample File

See `Docs/Sample-UpDock-Pro-Beta.updocklicense`.