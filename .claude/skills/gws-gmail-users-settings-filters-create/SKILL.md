---
name: gws-gmail-users-settings-filters-create
description: "Gmail: Create a server-side message filter (rule) that auto-labels matching mail."
---

# gmail users settings filters create

Create a persistent server-side filter. Gmail applies it automatically to matching
**future** mail (and offers to apply to existing matches in the UI). A mailbox can hold
at most 1,000 filters.

> ⚠️ Filters are persistent and silent. Validate with `--dry-run` first, and prefer
> label-only actions (`addLabelIds`) — never auto-archive (`removeLabelIds: ["INBOX"]`),
> delete (`["TRASH"]`), or mark read without explicit user intent.

## Usage

```bash
gws gmail users settings filters create --params '<JSON_PARAMS>' --json '<JSON_BODY>'
```

## Parameters (`--params` JSON)

| Parameter | Required | Description                                                   |
| --------- | -------- | ------------------------------------------------------------- |
| `userId`  | ✓        | The user's email address or `"me"` for the authenticated user |

## Request Body (`--json` JSON)

```json
{
  "criteria": { "from": "notifications@github.com" },
  "action": { "addLabelIds": ["Label_42"] }
}
```

### `criteria` fields (match conditions — combine with AND)

| Field           | Type    | Description                                              |
| --------------- | ------- | -------------------------------------------------------- |
| `from`          | String  | Sender. Supports `*@domain.com` and `domain.com`.       |
| `to`            | String  | Recipient.                                              |
| `subject`       | String  | Subject contains.                                       |
| `query`         | String  | Any Gmail search query (e.g. `"list:newsletters"`).     |
| `negatedQuery`  | String  | Gmail search query that must NOT match.                 |
| `hasAttachment` | Boolean | Only messages with attachments.                         |

### `action` fields

| Field           | Type     | Description                                            |
| --------------- | -------- | ----------------------------------------------------- |
| `addLabelIds`   | [String] | **Label IDs** (not names) to apply. Use `labels list`.|
| `removeLabelIds`| [String] | Label IDs to remove. Avoid for auto-curation.         |
| `forward`       | String   | Forwarding address. Do not use for auto-curation.     |

## Examples

```bash
# Validate locally first — does not call the API
gws gmail users settings filters create --params '{"userId": "me"}' \
  --json '{"criteria": {"from": "notifications@github.com"}, "action": {"addLabelIds": ["Label_42"]}}' --dry-run

# Create the filter
gws gmail users settings filters create --params '{"userId": "me"}' \
  --json '{"criteria": {"from": "notifications@github.com"}, "action": {"addLabelIds": ["Label_42"]}}'
```

## Tips

- `addLabelIds` takes label **IDs**, not display names. Resolve them with
  `gws gmail users labels list` and match on the `name` field.
- A sender filter generalizes; key it on the most specific stable criterion (an exact
  `from`, or `*@domain.com` only when the whole domain is consistent).
