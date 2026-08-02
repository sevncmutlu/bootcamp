#!/usr/bin/env bash

if [[ "${MAKI_ENV:-}" != "production" ]]; then
  echo "ERROR: MAKI_ENV must be exactly production." >&2
  return 1 2>/dev/null || exit 1
fi

required=(
  MAKI_BACKEND_URL MAKI_OIDC_ISSUER MAKI_OIDC_CLIENT_ID
  MAKI_OIDC_AUDIENCE MAKI_OIDC_REDIRECT_URI MAKI_PRIVACY_URL
  MAKI_TERMS_URL MAKI_BILLING_PRODUCT_ID MAKI_ENABLE_STORE_BILLING
)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: $name is required for a production release." >&2
    return 1 2>/dev/null || exit 1
  fi
done

if [[ "$MAKI_ENABLE_STORE_BILLING" != "true" ]]; then
  echo "ERROR: MAKI_ENABLE_STORE_BILLING must be true." >&2
  return 1 2>/dev/null || exit 1
fi
for url in "$MAKI_BACKEND_URL" "$MAKI_OIDC_ISSUER" "$MAKI_PRIVACY_URL" "$MAKI_TERMS_URL"; do
  if [[ "$url" != https://* ]]; then
    echo "ERROR: API, OIDC issuer and legal URLs must use https://" >&2
    return 1 2>/dev/null || exit 1
  fi
done

MAKI_RELEASE_DEFINES=(
  --dart-define=MAKI_ENV=production
  --dart-define=BACKEND_URL="$MAKI_BACKEND_URL"
  --dart-define=OIDC_ISSUER="$MAKI_OIDC_ISSUER"
  --dart-define=OIDC_CLIENT_ID="$MAKI_OIDC_CLIENT_ID"
  --dart-define=OIDC_AUDIENCE="$MAKI_OIDC_AUDIENCE"
  --dart-define=OIDC_REDIRECT_URI="$MAKI_OIDC_REDIRECT_URI"
  --dart-define=PRIVACY_URL="$MAKI_PRIVACY_URL"
  --dart-define=TERMS_URL="$MAKI_TERMS_URL"
  --dart-define=BILLING_PRODUCT_ID="$MAKI_BILLING_PRODUCT_ID"
  --dart-define=ENABLE_STORE_BILLING=true
)
