# Identity Guard

Identity Guard is a safety skill for OpenClaw that blocks sensitive requests unless the sender is authorized by `sender_id` (not by display name).

## Quickstart (60 seconds)

1. Get your `sender_id`:
   - Recommended: DM the bot with `/whoami`, then copy the ID.
   - Or run locally: `./scripts/whoami.sh`
2. Initialize config:
   - `./scripts/init.sh`
3. Verify:
   - `identities.json` should contain your `master_id`.

If `identities.json` is missing, it will be auto-created from `identities.json.template` (or as an empty config). Unconfigured configs still deny all sensitive requests by default.

## Files

- `SKILL.md` - The rules and trigger logic
- `identities.json` - Authorization config (required)
- `scripts/guard.sh` - Verification script used by the skill
- `scripts/whoami.sh` - Best-effort sender ID discovery from recent sessions
- `scripts/init.sh` - Interactive initialization for `identities.json`
- `scripts/add-user.sh` - Add allowlist entries

## identities.json format

```json
{
  "channels": {
    "feishu": {
      "master_id": "ou_xxxxx",
      "allowlist": []
    },
    "telegram": {
      "master_id": "123456789",
      "allowlist": []
    }
  },
  "global_allowlist": []
}
```

## Notes

- IDs are sensitive. In group chats, prefer DM for `/whoami`.
- If `sender_id` metadata is missing or untrusted, the skill must deny sensitive requests.
