# Actions registry

Each `*.json` here is one automation the top-level `gws-do` command can route to.
**Adding a new automation = dropping a new manifest in this folder.** No code changes.

## Manifest schema

```json
{
  "id": "my-automation",            // unique, kebab-case; used by --action
  "title": "Short human title",
  "description": "One or two sentences. The router reads this to match goals.",
  "keywords": ["words", "that", "hint", "the goal"],   // deterministic fallback routing
  "kind": "agent",                  // "agent" (runs a Claude/harness sub-agent) or "script"
  "target": "my-sub-agent",         // agent name in .claude/agents/, OR a path for scripts
  "interactive": true               // agents: true = conversational session, false = one-shot
}
```

## How routing uses it

1. **Agent route (primary):** `gws-do "<goal>"` sends your description + the catalog
   (id/title/description of every manifest) to the configured AI harness, which picks the
   best `id`.
2. **Keyword route (fallback):** if the harness is unavailable, the `keywords` are matched
   against the goal.
3. **Menu (last resort):** you pick from the list.

## Add one in 3 steps

1. Build the capability — either a sub-agent in `.claude/agents/<name>.md` (+ its
   `.allowlist`, + its `gws` prefixes in `.claude/settings.json`), or a script in `scripts/`.
2. Drop a manifest here pointing `target` at it.
3. `gws-do --list` to confirm it shows up. Done.

> Keep the safety model intact: a new **agent** must have a matching `.allowlist` and its
> `gws` commands listed in `settings.json` `allow` — never add `send`/`trash`/`delete`.
