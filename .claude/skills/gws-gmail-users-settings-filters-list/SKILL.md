---
name: gws-gmail-users-settings-filters-list
description: "Gmail: List the existing message filters (rules) in the user's mailbox."
---

# gmail users settings filters list

List all server-side message filters configured in the user's mailbox. Use this to
discover what filters already exist before creating a new one (avoid duplicates).

## Usage

```bash
gws gmail users settings filters list --params '<JSON_PARAMS>'
```

## Parameters (`--params` JSON)

| Parameter | Required | Default | Description                                                   |
| --------- | -------- | ------- | ------------------------------------------------------------- |
| `userId`  | ✓        | —       | The user's email address or `"me"` for the authenticated user |

## Response shape

Returns `{ "filter": [ { "id", "criteria", "action" }, ... ] }`:

```json
{
  "filter": [
    {
      "id": "ANe1Bmg...",
      "criteria": { "from": "notifications@github.com" },
      "action": { "addLabelIds": ["Label_42"] }
    }
  ]
}
```

- `criteria` fields include `from`, `to`, `subject`, `query`, `negatedQuery`,
  `hasAttachment`, `excludeChats`, `size`, `sizeComparison`.
- `action` fields include `addLabelIds`, `removeLabelIds`, `forward`.

## Example

```bash
gws gmail users settings filters list --params '{"userId": "me"}'
```
