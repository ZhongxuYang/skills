#!/bin/bash

# Identity Guard for OpenClaw
# Usage: ./guard.sh <sender_id> [channel]
# channel is optional - if not provided, checks all channels

SENDER_ID=$1
CHANNEL=$2

# Locate identities.json relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../identities.json"
TEMPLATE_FILE="$SCRIPT_DIR/../identities.json.template"

if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    else
        cat > "$CONFIG_FILE" <<EOF
{
  "channels": {},
  "global_allowlist": []
}
EOF
    fi
fi

if [ -z "$SENDER_ID" ]; then
    echo "Error: sender_id is required"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    if grep -q "$SENDER_ID" "$CONFIG_FILE"; then
        exit 0
    else
        exit 1
    fi
fi

# Reject uninitialized configs early
if jq -e '
  (
    (.channels | type == "object") and
    (
      .channels | to_entries[]? |
      ((.value.master_id // "") == "" or (.value.master_id // "") == "YOUR_SENDER_ID_HERE")
    )
  )
  or
  (
    ((.global_allowlist // []) | length) == 0 and
    ((.channels // {}) | to_entries[]? | (.value.allowlist // []) | length) == 0 and
    ((.channels // {}) | to_entries[]? | (.value.master_id // "") == "" or (.value.master_id // "") == "YOUR_SENDER_ID_HERE")
  )
' "$CONFIG_FILE" > /dev/null 2>&1; then
    exit 1
fi

# 1. Check Global Allowlist
if jq -e ".global_allowlist | contains([\"$SENDER_ID\"])" "$CONFIG_FILE" > /dev/null 2>&1; then
    exit 0
fi

# 2. If channel is provided, check channel-specific permissions
if [ -n "$CHANNEL" ]; then
    # Check Channel Master ID
    MASTER_ID=$(jq -r ".channels.\"$CHANNEL\".master_id // empty" "$CONFIG_FILE" 2>/dev/null)
    if [ "$SENDER_ID" == "$MASTER_ID" ]; then
        exit 0
    fi
    
    # Check Channel Allowlist
    if jq -e ".channels.\"$CHANNEL\".allowlist | contains([\"$SENDER_ID\"])" "$CONFIG_FILE" > /dev/null 2>&1; then
        exit 0
    fi
fi

# 3. If no channel or channel check failed, check if sender is a master in ANY channel
if jq -e ".channels | to_entries[] | select(.value.master_id == \"$SENDER_ID\")" "$CONFIG_FILE" > /dev/null 2>&1; then
    exit 0
fi

# 4. Check if sender is in any channel's allowlist
if jq -e ".channels | to_entries[] | select(.value.allowlist | contains([\"$SENDER_ID\"]))" "$CONFIG_FILE" > /dev/null 2>&1; then
    exit 0
fi

exit 1
