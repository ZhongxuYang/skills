#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../identities.json"

usage() {
  cat <<EOF
Usage: ./add-user.sh <sender_id> [channel]
If channel is omitted, the sender is added to global_allowlist.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

SENDER_ID="$1"
CHANNEL="${2:-}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Missing ${CONFIG_FILE}. Run ./scripts/init.sh first." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for add-user.sh" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"

if [[ -n "${CHANNEL}" ]]; then
  jq --arg channel "${CHANNEL}" --arg sender "${SENDER_ID}" '
    .channels = (.channels // {}) |
    .channels[$channel] = (.channels[$channel] // {}) |
    .channels[$channel].allowlist = ((.channels[$channel].allowlist // []) + [$sender] | unique) |
    .global_allowlist = (.global_allowlist // [])
  ' "${CONFIG_FILE}" > "${TMP_FILE}"
else
  jq --arg sender "${SENDER_ID}" '
    .global_allowlist = ((.global_allowlist // []) + [$sender] | unique) |
    .channels = (.channels // {})
  ' "${CONFIG_FILE}" > "${TMP_FILE}"
fi

mv "${TMP_FILE}" "${CONFIG_FILE}"
echo "Updated ${CONFIG_FILE}"
