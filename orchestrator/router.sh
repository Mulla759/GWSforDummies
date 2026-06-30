#!/usr/bin/env bash
# orchestrator/router.sh — the routing + dispatch core for `gws-do`.
# Sourced by bin/gws-do. Pure bash + jq. Knows nothing about any specific AI
# harness — it calls the adapter functions (harness_*) loaded from harness/.

# --- locations (ROOT is exported by bin/gws-do) ---
ACTIONS_DIR="$ROOT/actions"
HARNESS_DIR="$ROOT/harness"

# --- load the configured harness adapter ---
load_harness() {
  # shellcheck disable=SC1091
  source "$HARNESS_DIR/harness.config"
  local adapter="$HARNESS_DIR/${HARNESS:-claude-code}.sh"
  [ -f "$adapter" ] || { echo "router: harness adapter not found: $adapter" >&2; return 1; }
  # shellcheck disable=SC1090
  source "$adapter"
}

# --- registry ---
registry_catalog() {            # JSON array of all actions (full manifests)
  jq -s '.' "$ACTIONS_DIR"/*.json
}
registry_brief() {              # JSON array of {id,title,description} for routing
  jq -s 'map({id,title,description})' "$ACTIONS_DIR"/*.json
}
registry_has() {                # $1=id -> 0 if an action with that id exists
  jq -e -s --arg id "$1" 'any(.[]; .id==$id)' "$ACTIONS_DIR"/*.json >/dev/null 2>&1
}
registry_field() {              # $1=id $2=field -> value
  jq -r -s --arg id "$1" --arg f "$2" '.[] | select(.id==$id) | .[$f] // empty' "$ACTIONS_DIR"/*.json | head -1
}

# --- deterministic keyword routing (fallback / offline) ---
route_keyword() {               # $1=goal -> best id or empty
  registry_catalog | jq -r --arg g "$1" '
    ($g | ascii_downcase) as $goal
    | .[]
    | .id as $id
    | { id: $id, score: ([ .keywords[] | ascii_downcase as $k | select($goal | contains($k)) ] | length) }
    | select(.score > 0)
    | "\(.score) \(.id)"
  ' | sort -rn | awk 'NR==1{print $2}'
}

# --- interactive menu (last-resort fallback) ---
menu_pick() {                   # prints chosen id to stdout (prompts on stderr)
  local ids=() titles=() id title
  while IFS=$'\t' read -r id title; do ids+=("$id"); titles+=("$title"); done \
    < <(registry_catalog | jq -r '.[] | .id + "\t" + .title')
  {
    echo "Which action?"
    local j
    for ((j=0; j<${#ids[@]}; j++)); do printf "  %d) %s — %s\n" "$((j+1))" "${ids[$j]}" "${titles[$j]}"; done
    printf "Pick [1-%d]: " "${#ids[@]}"
  } >&2
  local pick; read -r pick
  [[ "$pick" =~ ^[0-9]+$ ]] && [ "$pick" -ge 1 ] && [ "$pick" -le "${#ids[@]}" ] && printf '%s' "${ids[$((pick-1))]}"
}

# --- the route decision: describe -> route (agent first) -> id ---
route_goal() {                  # $1=goal -> prints chosen id (or empty)
  local goal="$1" id=""
  # 1) explicit override wins
  if [ -n "${FORCE_ACTION:-}" ]; then
    registry_has "$FORCE_ACTION" && { printf '%s' "$FORCE_ACTION"; return 0; }
    echo "router: unknown --action '$FORCE_ACTION'" >&2; return 1
  fi
  # 2) primary: route THROUGH the agent harness (the "additional logic" layer)
  if [ "${ROUTER:-agent}" = "agent" ] && harness_check 2>/dev/null; then
    id=$(harness_route "$goal" "$(registry_brief)")
    if [ -n "$id" ] && registry_has "$id"; then printf '%s' "$id"; return 0; fi
  fi
  # 3) deterministic keyword fallback (works with no AI)
  id=$(route_keyword "$goal")
  if [ -n "$id" ]; then printf '%s' "$id"; return 0; fi
  # 4) last resort: ask the human
  menu_pick
}

# --- dispatch a chosen action ---
dispatch() {                    # $1=id  $2=goal
  local id="$1" goal="$2" kind target interactive
  kind=$(registry_field "$id" kind)
  target=$(registry_field "$id" target)
  interactive=$(registry_field "$id" interactive)
  case "$kind" in
    agent)
      command -v harness_run_agent >/dev/null || load_harness
      harness_run_agent "$target" "$goal" "${interactive:-true}"
      ;;
    script)
      # scripts are deterministic and need no AI; pass any trailing args through
      bash "$ROOT/$target" ${SCRIPT_ARGS:-}
      ;;
    *)
      echo "router: unknown kind '$kind' for action '$id'" >&2; return 1;;
  esac
}
