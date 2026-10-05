#!/bin/sh
# Self-contained test for bin/ws-map. Builds throwaway repos under a temp dir; no network.
set -u

HERE=$(cd "$(dirname "$0")" && pwd -P)
WS_MAP="$HERE/../bin/ws-map"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FAILS=0

g() { git -c user.name=test -c user.email=test@example.com -c init.defaultBranch=main "$@" >/dev/null 2>&1; }

fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
contains() { printf '%s' "$1" | grep -qF -- "$2" || fail "$3 (missing: $2)"; }
lacks() { printf '%s' "$1" | grep -qF -- "$2" && fail "$3 (unexpected: $2)"; return 0; }
empty() { [ -z "$1" ] || fail "$2 (expected no output, got: $(printf '%s' "$1" | head -n 1))"; }

# run <project-dir> [ws_root]  -> stdout of ws-map with ws_root configured, exit code checked
run() {
  out=$(env -u WS_ROOT CLAUDE_PLUGIN_OPTION_WS_ROOT="${2:-$ROOT}" CLAUDE_PROJECT_DIR="$1" "$WS_MAP" </dev/null)
  code=$?
  [ "$code" -eq 0 ] || fail "exit code $code for project $1"
  printf '%s' "$out"
}

# auto <project-dir>  -> stdout of ws-map with NO ws_root configured
auto() {
  out=$(env -u WS_ROOT -u CLAUDE_PLUGIN_OPTION_WS_ROOT CLAUDE_PROJECT_DIR="$1" "$WS_MAP" </dev/null)
  code=$?
  [ "$code" -eq 0 ] || fail "exit code $code for project $1 (auto)"
  printf '%s' "$out"
}

# --- fixture: origin + workspace -------------------------------------------
ROOT="$TMP/ws"
mkdir -p "$ROOT" "$TMP/seed" "$TMP/elsewhere"
g init --bare "$TMP/origin.git"
g -C "$TMP/seed" init
g -C "$TMP/seed" commit --allow-empty -m init
g -C "$TMP/seed" push "$TMP/origin.git" main

g clone "$TMP/origin.git" "$ROOT/alpha"                 # on default branch
g clone "$TMP/origin.git" "$ROOT/beta"                  # feature branch -> ★
g -C "$ROOT/beta" switch -c feature
mkdir "$ROOT/gamma"; g -C "$ROOT/gamma" init             # no remote -> default ?
g -C "$ROOT/gamma" commit --allow-empty -m init
g clone "$TMP/origin.git" "$ROOT/delta"                  # detached HEAD
g -C "$ROOT/delta" checkout --detach
mkdir -p "$ROOT/notes" "$ROOT/.tasks/t1/alpha"           # not repos -> skipped

# --- root mode ---------------------------------------------------------------
out=$(run "$ROOT")
contains "$out" "# Multi-repo workspace" "root: rules printed"
contains "$out" "— 4 repos" "root: repo count"
printf '%s\n' "$out" | grep -qE -- "- delta \| \(detached [0-9a-f]{7}\) ★ \(default: main\) \|" || fail "root: detached HEAD shown"
contains "$out" "- beta | feature ★ (default: main) |" "root: ★ on feature branch"
contains "$out" "- alpha | main |" "root: alpha listed"
contains "$out" "- gamma | main |" "root: gamma listed"
lacks "$out" "alpha | main ★" "root: no ★ on default branch"
lacks "$out" "gamma | main ★" "root: no ★ when default unknown"
lacks "$out" "notes" "root: non-repo dir skipped"
lacks "$out" ".tasks" "root: hidden task dir skipped"
printf '%s\n' "$out" | grep -qE -- "- alpha \| main \| [0-9]{4}-[0-9]{2}-[0-9]{2}$" || fail "root: last-commit date format"

# --- repo mode ---------------------------------------------------------------
printf 'alpha rules\n' > "$ROOT/alpha/AGENTS.md"
mkdir -p "$ROOT/alpha/src"
out=$(run "$ROOT/alpha")
contains "$out" "## This repo's AGENTS.md" "repo: AGENTS.md header"
contains "$out" "alpha rules" "repo: AGENTS.md content"
lacks "$out" "Workspace map" "repo: no map in repo session"
out=$(run "$ROOT/alpha/src")
contains "$out" "alpha rules" "repo: subdirectory resolves repo top"

printf 'beta agents\n' > "$ROOT/beta/AGENTS.md"
printf 'beta claude\n' > "$ROOT/beta/CLAUDE.md"
empty "$(run "$ROOT/beta")" "repo: CLAUDE.md present -> nothing"
empty "$(run "$ROOT/gamma")" "repo: no AGENTS.md -> nothing"

# --- outside / missing root ----------------------------------------------------
empty "$(run "$TMP/elsewhere")" "outside root -> nothing"
empty "$(run "$ROOT" "$TMP/does-not-exist")" "missing configured root -> nothing"

# --- repo mode is independent of the root --------------------------------------
mkdir "$TMP/loose"; g -C "$TMP/loose" init
printf 'loose rules\n' > "$TMP/loose/AGENTS.md"
contains "$(run "$TMP/loose")" "loose rules" "repo outside root: AGENTS.md fallback still applies"

# --- auto-detect when nothing is configured -----------------------------------
out=$(auto "$ROOT")
contains "$out" "— 4 repos" "auto: non-repo dir with >=2 child repos is a root"
contains "$out" "# Multi-repo workspace" "auto: rules printed"
mkdir -p "$TMP/single"; g clone "$TMP/origin.git" "$TMP/single/only"
empty "$(auto "$TMP/single")" "auto: a single child repo is not a workspace"
empty "$(auto "$TMP/elsewhere")" "auto: dir without repos -> nothing"
contains "$(auto "$ROOT/alpha")" "alpha rules" "auto: repo mode still works"
out=$(auto "$ROOT/alpha")
lacks "$out" "Workspace map" "auto: a repo is never treated as a root"

# --- explicit config disables auto-detect elsewhere ------------------------------
mkdir -p "$TMP/other"; g clone "$TMP/origin.git" "$TMP/other/r1"; g clone "$TMP/origin.git" "$TMP/other/r2"
empty "$(run "$TMP/other")" "configured: another multi-repo dir is not a root"

# --- configuration fallbacks ---------------------------------------------------
# shellcheck disable=SC2088  # deliberately pass an unexpanded "~" like a configured value would
out=$(HOME="$TMP" CLAUDE_PLUGIN_OPTION_WS_ROOT="~/ws" CLAUDE_PROJECT_DIR="$ROOT" "$WS_MAP" </dev/null)
contains "$out" "— 4 repos" "config: leading ~ expanded"
out=$(env -u CLAUDE_PLUGIN_OPTION_WS_ROOT WS_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$ROOT" "$WS_MAP" </dev/null)
contains "$out" "— 4 repos" "config: WS_ROOT fallback"
out=$(cd "$ROOT" && env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_OPTION_WS_ROOT="$ROOT" "$WS_MAP" </dev/null)
contains "$out" "— 4 repos" "config: PWD fallback for project dir"

if [ "$FAILS" -eq 0 ]; then echo "PASS: ws-map"; exit 0; fi
echo "$FAILS failure(s)"; exit 1
