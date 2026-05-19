#!/usr/bin/env bash
# milestone-sync.sh — R13 helper: milestone como propiedad compartida del equipo.
#
# Sincroniza SOLO <path>/<slug>.md contra una rama canónica (default: develop)
# vía un worktree aislado bajo .git/ — nunca toca tu rama de código ni tu
# working tree. Opt-in: si .milestones/config.yml no trae milestone_sync.enabled
# todo es no-op silencioso. Nunca aborta la operación de milestone que lo llama.
#
# Uso:
#   milestone-sync.sh check <repo_root> <slug>
#   milestone-sync.sh pull  <repo_root> <slug>
#   milestone-sync.sh push  <repo_root> <slug>
#   milestone-sync.sh stamp <repo_root> <slug> <X.Y> <pr_number>
#
# Salidas (stdout, una palabra-estado; detalle a stderr):
#   check → up-to-date | remote-newer | diverged | local-only | noop:<razón>
#   pull  → pulled | noop:<razón>
#   push  → pushed | commit-pending-push:<cmd> | noop:<razón>
#   stamp → stamped | noop:<razón> | (delega salida de push)
set -o pipefail

cmd="${1:-}"; root="${2:-}"; slug="${3:-}"
log() { printf '%s\n' "$*" >&2; }
noop() { echo "noop:$1"; exit 0; }

[ -n "$cmd" ] && [ -n "$root" ] && [ -n "$slug" ] || { log "args: <cmd> <repo_root> <slug> [...]"; echo "noop:bad-args"; exit 0; }

CFG="$root/.milestones/config.yml"

cfg() { # key → value (dentro del bloque milestone_sync:)
  [ -f "$CFG" ] || return 0
  awk -v k="$1" '
    /^milestone_sync:[[:space:]]*$/ {inblk=1; next}
    inblk && /^[^[:space:]#]/ {inblk=0}
    inblk {
      l=$0; sub(/#.*/,"",l)
      if (match(l, "^[[:space:]]+" k "[[:space:]]*:[[:space:]]*")) {
        v=substr(l, RLENGTH+1)
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); gsub(/^["'\'']|["'\'']$/,"",v)
        print v; exit
      }
    }' "$CFG" 2>/dev/null
}

enabled="$(cfg enabled)"
[ "$enabled" = "true" ] || noop "disabled"
git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || noop "not-git"
git -C "$root" remote get-url origin >/dev/null 2>&1 || noop "no-remote"

path="$(cfg path)"; [ -n "$path" ] || path=".milestones"
file_rel="$path/$slug.md"
local_file="$root/$file_rel"

branch="$(cfg branch)"
if [ -z "$branch" ]; then
  if git -C "$root" ls-remote --heads origin develop 2>/dev/null | grep -q .; then
    branch="develop"
  else
    branch="$(git -C "$root" remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/{print $2; exit}')"
  fi
fi
[ -n "$branch" ] || noop "no-branch"
git -C "$root" ls-remote --heads origin "$branch" 2>/dev/null | grep -q . || noop "no-branch"
git -C "$root" fetch -q origin "$branch" 2>/dev/null || true

upd() { grep -m1 '^updated:' "$1" 2>/dev/null | sed "s/^updated:[[:space:]]*//; s/[\"' ]//g"; }

remote_tmp="$(mktemp)"; trap 'rm -f "$remote_tmp"' EXIT
have_remote=0
if git -C "$root" show "origin/$branch:$file_rel" >"$remote_tmp" 2>/dev/null; then have_remote=1; fi

status() {
  if [ ! -f "$local_file" ] && [ "$have_remote" = 1 ]; then echo "remote-newer"; return; fi
  if [ -f "$local_file" ] && [ "$have_remote" = 0 ]; then echo "local-only"; return; fi
  if [ ! -f "$local_file" ] && [ "$have_remote" = 0 ]; then echo "noop:no-change"; return; fi
  if diff -q "$local_file" "$remote_tmp" >/dev/null 2>&1; then echo "up-to-date"; return; fi
  local lu ru; lu="$(upd "$local_file")"; ru="$(upd "$remote_tmp")"
  if [ -n "$lu" ] && [ -n "$ru" ]; then
    if [ "$ru" \> "$lu" ]; then echo "remote-newer"; return; fi
    if [ "$lu" \> "$ru" ]; then echo "local-newer"; return; fi
  fi
  echo "diverged"
}

case "$cmd" in
  check)
    s="$(status)"; [ "$s" = "local-newer" ] && s="local-only"
    echo "$s" ;;

  pull)
    [ "$have_remote" = 1 ] || noop "no-change"
    mkdir -p "$(dirname "$local_file")"
    cp "$remote_tmp" "$local_file"
    log "milestone adoptado desde origin/$branch"
    echo "pulled" ;;

  stamp)
    xy="${4:-}"; pr="${5:-}"
    [ -n "$xy" ] && [ -n "$pr" ] || { log "stamp: faltan <X.Y> <pr>"; noop "bad-args"; }
    [ -f "$local_file" ] || noop "no-change"
    # Solo subtareas [~]; parser-safe (no cambia checkbox ni marcadores).
    if ! grep -qE "^- \[~\] ${xy}([^0-9].*)?$|^- \[~\] ${xy} " "$local_file"; then
      log "subtarea $xy no está en [~]; promover con evidencia antes de sellar"
      noop "subtask-not-tilde"
    fi
    grep -q "PR #${pr}" "$local_file" 2>/dev/null && { log "ya sellada con PR #${pr}"; noop "already-stamped"; }
    tmp="$(mktemp)"
    awk -v xy="$xy" -v pr="$pr" '
      $0 ~ "^- \\[~\\] " xy "([^0-9]|$)" && idx==0 { sub(/[[:space:]]*$/,""); $0=$0 " `⏳ PR #" pr "`"; idx=1 }
      { print }
    ' "$local_file" >"$tmp" && mv "$tmp" "$local_file"
    log "sellada $xy → PR #$pr"
    exec "$0" push "$root" "$slug" ;;

  push)
    [ -f "$local_file" ] || noop "no-change"
    if [ "$have_remote" = 1 ] && diff -q "$local_file" "$remote_tmp" >/dev/null 2>&1; then noop "no-change"; fi
    s="$(status)"
    if [ "$s" = "diverged" ] || [ "$s" = "remote-newer" ]; then
      log "DIVERGENCIA con origin/$branch — no se fuerza. Haz 'pull' y reconcilia ## Contexto (append-only por fecha)."
      echo "commit-pending-push:git -C $root <reconciliar manualmente; ver git-sync.md §9>"
      exit 0
    fi
    gid_e="$(git -C "$root" config user.email 2>/dev/null)"; [ -n "$gid_e" ] || gid_e="milestone-sync@local"
    gid_n="$(git -C "$root" config user.name 2>/dev/null)"; [ -n "$gid_n" ] || gid_n="milestone-sync"
    msg="chore(milestone): sync $slug [skip ci]"
    cur="$(git -C "$root" branch --show-current 2>/dev/null)"

    if [ "$cur" = "$branch" ]; then
      # Working tree principal ya en la rama canónica: commit SOLO del pathspec.
      git -C "$root" add -- "$file_rel" 2>/dev/null
      git -C "$root" diff --cached --quiet -- "$file_rel" 2>/dev/null && noop "no-change"
      git -C "$root" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || { log "commit falló"; noop "commit-failed"; }
      if git -C "$root" push -q origin "$branch" 2>/dev/null; then echo "pushed"
      else echo "commit-pending-push:git -C $root push origin $branch"; fi
      exit 0
    fi

    # Caso normal: estás en feature/* → worktree aislado en .git/
    WT="$root/.git/milestone-sync-wt"
    if [ -d "$WT" ] && git -C "$WT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$WT" fetch -q origin "$branch" 2>/dev/null || true
      git -C "$WT" reset -q --hard "origin/$branch" 2>/dev/null
      git -C "$WT" clean -qfd 2>/dev/null || true
    else
      git -C "$root" worktree prune 2>/dev/null || true
      rm -rf "$WT"
      git -C "$root" worktree add -q --no-checkout "$WT" "origin/$branch" 2>/dev/null || { log "no se pudo crear worktree"; noop "worktree-failed"; }
      git -C "$WT" sparse-checkout init --cone 2>/dev/null || true
      git -C "$WT" sparse-checkout set "$path" 2>/dev/null || true
      git -C "$WT" checkout -q 2>/dev/null || true
    fi
    mkdir -p "$WT/$(dirname "$file_rel")"
    cp "$local_file" "$WT/$file_rel"
    git -C "$WT" add -- "$file_rel" 2>/dev/null
    git -C "$WT" diff --cached --quiet -- "$file_rel" 2>/dev/null && noop "no-change"
    git -C "$WT" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || { log "commit (worktree) falló"; noop "commit-failed"; }
    if git -C "$WT" push -q origin "HEAD:$branch" 2>/dev/null; then
      log "milestone sincronizado a origin/$branch (worktree aislado)"
      echo "pushed"
    else
      echo "commit-pending-push:git -C $WT push origin HEAD:$branch"
    fi ;;

  *)
    log "comando desconocido: $cmd"; noop "bad-args" ;;
esac
