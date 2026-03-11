#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../identities.json"

prompt() {
  local label="$1"
  local value=""
  read -r -p "${label}: " value
  echo "${value}"
}

CHANNEL="$(prompt "Channel (e.g., feishu, telegram)")"
SENDER_ID="$(prompt "Your sender_id")"

if [[ -z "${CHANNEL}" || -z "${SENDER_ID}" ]]; then
  echo "Both channel and sender_id are required." >&2
  echo "Tip: run ./scripts/whoami.sh or ask the bot with /whoami to get your sender_id." >&2
  exit 1
fi

if [[ -f "${CONFIG_FILE}" ]]; then
  cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
fi

if command -v jq >/dev/null 2>&1; then
  TMP_FILE="$(mktemp)"
  if [[ -f "${CONFIG_FILE}" ]]; then
    jq --arg channel "${CHANNEL}" --arg sender "${SENDER_ID}" '
      .channels = (.channels // {}) |
      .channels[$channel] = (.channels[$channel] // {}) |
      .channels[$channel].master_id = $sender |
      .channels[$channel].allowlist = (.channels[$channel].allowlist // []) |
      .global_allowlist = (.global_allowlist // [])
    ' "${CONFIG_FILE}" > "${TMP_FILE}"
  else
    jq -n --arg channel "${CHANNEL}" --arg sender "${SENDER_ID}" '
      {
        channels: {
          ($channel): {
            master_id: $sender,
            allowlist: []
          }
        },
        global_allowlist: []
      }
    ' > "${TMP_FILE}"
  fi
  mv "${TMP_FILE}" "${CONFIG_FILE}"
else
  cat > "${CONFIG_FILE}" <<EOF
{
  "channels": {
    "${CHANNEL}": {
      "master_id": "${SENDER_ID}",
      "allowlist": []
    }
  },
  "global_allowlist": []
}
EOF
fi

echo "Updated ${CONFIG_FILE}"
