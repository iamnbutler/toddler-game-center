#!/usr/bin/env bash
# Build, sign, and optionally notarize the macOS app with a Developer ID.
# Mirrors Ace's macOS signing flow (.github/actions/macos-sign in iamnbutler's ace repo):
# hardened runtime + secure timestamp, notarytool with an App Store Connect API key, staple, verify.
#
# Usage:
#   scripts/sign-macos.sh            # build + sign
#   scripts/sign-macos.sh --open     # build + sign + launch
#   op run --env-file scripts/signing.env -- scripts/sign-macos.sh   # + notarize (1Password)
#
# Environment:
#   DEVELOPER_ID                 Signing identity (name or SHA-1). Defaults to the first
#                                "Developer ID Application" identity in the keychain.
#   APPLE_API_KEY_ID             App Store Connect API key ID        } enable
#   APPLE_API_ISSUER             App Store Connect API issuer ID     } notarization
#   APPLE_API_KEY_PATH           Path to the AuthKey_<id>.p8 file, or
#   APPLE_API_PRIVATE_KEY        the .p8 contents (written to a temp file and removed)
set -euo pipefail

cd "$(dirname "$0")/.."

open_app=0
[[ "${1:-}" == "--open" ]] && open_app=1

derived=".build/DerivedData"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if [[ -z "${APPLE_API_KEY_PATH:-}" && -n "${APPLE_API_PRIVATE_KEY:-}" ]]; then
	APPLE_API_KEY_PATH="$tmp/AuthKey_${APPLE_API_KEY_ID:-key}.p8"
	(umask 077; printf '%s\n' "$APPLE_API_PRIVATE_KEY" > "$APPLE_API_KEY_PATH")
fi
entitlements="App/ToddlerGameCenter.entitlements"

identity="${DEVELOPER_ID:-}"
if [[ -z "$identity" ]]; then
	identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}')
fi
if [[ -z "$identity" ]]; then
	echo "error: no Developer ID Application identity found; set DEVELOPER_ID" >&2
	exit 1
fi

echo "==> Generating Xcode project"
xcodegen generate --quiet

echo "==> Building (unsigned)"
xcodebuild build \
	-project ToddlerGameCenter.xcodeproj \
	-scheme ToddlerGameCenter \
	-configuration Release \
	-destination 'generic/platform=macOS' \
	-derivedDataPath "$derived" \
	CODE_SIGNING_ALLOWED=NO \
	-quiet

app="$derived/Build/Products/Release/Toddler Game Center.app"
[[ -d "$app" ]] || { echo "error: missing $app" >&2; exit 1; }

echo "==> Signing with $identity"
codesign --force --deep --timestamp --options runtime \
	--entitlements "$entitlements" \
	--sign "$identity" \
	"$app"
codesign --verify --deep --strict --verbose=2 "$app"

if [[ -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER:-}" && -n "${APPLE_API_KEY_PATH:-}" ]]; then
	echo "==> Notarizing"
	zip="$tmp/notarize.zip"
	ditto -c -k --keepParent "$app" "$zip"
	xcrun notarytool submit "$zip" \
		--key "$APPLE_API_KEY_PATH" \
		--key-id "$APPLE_API_KEY_ID" \
		--issuer "$APPLE_API_ISSUER" \
		--wait --timeout 20m
	xcrun stapler staple "$app"
	spctl --assess --type execute --verbose=2 "$app"
else
	echo "==> Skipping notarization (set APPLE_API_KEY_ID, APPLE_API_ISSUER, APPLE_API_KEY_PATH or APPLE_API_PRIVATE_KEY)"
fi

echo "==> Signed: $app"
[[ $open_app == 1 ]] && open "$app"
exit 0
