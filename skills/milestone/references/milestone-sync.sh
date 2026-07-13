#!/usr/bin/env bash
# milestone-sync.sh — R13/R14 helper: milestone como propiedad compartida del equipo.
#
# Sincroniza SOLO <path>/<slug>.md contra una rama canónica (default: develop)
# vía un worktree aislado bajo .git/ — nunca toca tu rama de código ni tu
# working tree. Opt-in: si .milestones/config.yml no trae milestone_sync.enabled
# todo es no-op silencioso. Nunca aborta la operación de milestone que lo llama.
#
# Modo central (opt-in por ubicación): si el proyecto NO tiene
# .milestones/config.yml pero existe ~/.claude/projects/<clave>/milestones/config.yml
# (repo central de memorias; <clave> = path absoluto del proyecto con '/'→'-'),
# el almacén autoritativo vive ALLÍ y todas las operaciones (check/pull/push/
# claim/release/claims/stale/stamp) se redirigen a ese repo. El repo del
# proyecto queda sin rastro de planificación interna. Ver git-sync.md §2b.
# Override del root central (tests): MILESTONE_CENTRAL_ROOT.
#
# Uso:
#   milestone-sync.sh check   <repo_root> <slug>
#   milestone-sync.sh pull    <repo_root> <slug>
#   milestone-sync.sh push    <repo_root> <slug>
#   milestone-sync.sh stamp   <repo_root> <slug> <X.Y> <pr_number>
#   milestone-sync.sh claim   <repo_root> <slug> <X.Y>             # R14
#   milestone-sync.sh release <repo_root> <slug> <X.Y> [--force]   # R14
#   milestone-sync.sh claims  <repo_root> <slug>                   # R14
#   milestone-sync.sh stale   <repo_root> <slug> [hours]           # R14 (default 24h)
#
# Salidas (stdout, una palabra-estado; detalle a stderr):
#   check    → up-to-date | remote-newer | diverged | local-only | noop:<razón>
#   pull     → pulled | noop:<razón>
#   push     → pushed | commit-pending-push:<cmd> | noop:<razón>
#   stamp    → stamped | noop:<razón> | (delega salida de push)
#   claim    → claimed | already-claimed:<handle> | not-claimable:<estado> | race-lost:<handle> | noop:<razón>
#   release  → released | not-claimer:<handle> | not-claimed | noop:<razón>
#   claims   → lista TSV: <X.Y>\t<handle>\t<YYYY-MM-DD HH:MM>  (vacío si ninguno)
#   stale    → lista TSV de claims con edad > hours: <X.Y>\t<handle>\t<age_hours>
set -o pipefail

cmd="${1:-}"; root="${2:-}"; slug="${3:-}"
log() { printf '%s\n' "$*" >&2; }
noop() { echo "noop:$1"; exit 0; }
cleanup() { [ -n "${remote_tmp:-}" ] && rm -f "$remote_tmp"; [ -n "${wt_tmp:-}" ] && rm -f "$wt_tmp"; [ -n "${aux_tmp:-}" ] && rm -f "$aux_tmp"; }
trap cleanup EXIT

[ -n "$cmd" ] && [ -n "$root" ] && [ -n "$slug" ] || { log "args: <cmd> <repo_root> <slug> [...]"; echo "noop:bad-args"; exit 0; }

# Resolución de config: la local (.milestones/ del proyecto) tiene precedencia.
# Si no existe, se intenta el modo central (repo de memorias). Si ambas
# existieran, gana la local (migración pendiente — ver git-sync.md §2b).
central_mode=0
CFG="$root/.milestones/config.yml"
if [ ! -f "$CFG" ]; then
  central_base="${MILESTONE_CENTRAL_ROOT:-$HOME/.claude/projects}"
  root_abs="$(cd "$root" 2>/dev/null && pwd)"
  if [ -n "$root_abs" ] && [ -d "$central_base" ]; then
    mkey="$(printf '%s' "$root_abs" | tr '/' '-')"
    if [ -f "$central_base/$mkey/milestones/config.yml" ]; then
      CFG="$central_base/$mkey/milestones/config.yml"
      root="$central_base"
      central_mode=1
    fi
  fi
fi

cfg() {
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

path="$(cfg path)"
if [ -z "$path" ]; then
  if [ "$central_mode" = 1 ]; then path="$mkey/milestones"; else path=".milestones"; fi
fi
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
if git -C "$root" fetch -q origin "$branch" 2>/dev/null; then
  fetch_ok=1
else
  fetch_ok=0
fi

user_handle() {
  # Formato: "Nombre Completo (handle)" si hay ambos.
  # Fallback: solo lo que esté disponible (name | handle | $USER).
  local e n eprefix
  n="$(git -C "$root" config user.name 2>/dev/null)"
  e="$(git -C "$root" config user.email 2>/dev/null)"
  eprefix=""
  [ -n "$e" ] && eprefix="${e%%@*}"
  if [ -n "$n" ] && [ -n "$eprefix" ]; then
    printf '%s (%s)\n' "$n" "$eprefix"
    return
  fi
  if [ -n "$n" ]; then printf '%s\n' "$n"; return; fi
  if [ -n "$eprefix" ]; then printf '%s\n' "$eprefix"; return; fi
  printf '%s\n' "${USER:-anon}"
}

upd() { grep -m1 '^updated:' "$1" 2>/dev/null | sed "s/^updated:[[:space:]]*//; s/[\"' ]//g"; }

remote_tmp="$(mktemp)"
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

# --- helpers de subtarea: matching SIN regex complejos para evitar líos de escape ---
# Una línea de subtarea válida tiene SIEMPRE el prefijo "- [X] N.M " donde X ∈ { " ", ">", "~", "x", "-" }
# Devuelve por stdout la primera línea cuyo X.Y coincida; vacío si no.
find_subtask_line() {
  local file="$1" xy="$2"
  awk -v target="$xy" '
    function is_subtask_line(line,    s) {
      if (length(line) < 7) return 0
      if (substr(line,1,3) != "- [") return 0
      if (substr(line,5,2) != "] ") return 0
      s = substr(line,4,1)
      if (index(" >~x-", s) == 0) return 0
      return 1
    }
    function get_xy(line,    rest, m) {
      rest = substr(line, 7)
      if (match(rest, /^[0-9]+\.[0-9]+/)) {
        return substr(rest, RSTART, RLENGTH)
      }
      return ""
    }
    {
      if (is_subtask_line($0) && get_xy($0) == target) { print; exit }
    }
  ' "$file" 2>/dev/null
}

# Reemplaza la línea de la subtarea X.Y por una nueva línea dada. Idempotente:
# si no encuentra X.Y, deja el archivo intacto. Retorna 0 si reemplazó, 1 si no.
replace_subtask_line() {
  local file="$1" xy="$2" new_line="$3"
  aux_tmp="$(mktemp)"
  awk -v target="$xy" -v new_line="$new_line" '
    function is_subtask_line(line,    s) {
      if (length(line) < 7) return 0
      if (substr(line,1,3) != "- [") return 0
      if (substr(line,5,2) != "] ") return 0
      s = substr(line,4,1)
      if (index(" >~x-", s) == 0) return 0
      return 1
    }
    function get_xy(line,    rest) {
      rest = substr(line, 7)
      if (match(rest, /^[0-9]+\.[0-9]+/)) {
        return substr(rest, RSTART, RLENGTH)
      }
      return ""
    }
    {
      if (!done && is_subtask_line($0) && get_xy($0) == target) {
        print new_line; done=1; next
      }
      print
    }
    END { exit (done ? 0 : 1) }
  ' "$file" > "$aux_tmp"
  local rc=$?
  if [ "$rc" = 0 ]; then mv "$aux_tmp" "$file"; aux_tmp=""; return 0
  else rm -f "$aux_tmp"; aux_tmp=""; return 1; fi
}

# Inserta la anotación 🔒 antes de la última " [" (etiqueta [Dept]) de la línea.
# Si no hay " [", la añade al final.
inject_claim_annotation() {
  local line="$1" handle="$2" ts="$3"
  python3 - "$line" "$handle" "$ts" <<'PYEOF' 2>/dev/null || printf '%s `🔒 %s · %s`\n' "$line" "$handle" "$ts"
import sys
line, handle, ts = sys.argv[1], sys.argv[2], sys.argv[3]
ann = f"`🔒 {handle} · {ts}`"
# Encontrar la última ocurrencia de " [" (etiqueta [Dept])
idx = line.rfind(' [')
if idx == -1:
    print(f"{line} {ann}")
else:
    head = line[:idx]
    tail = line[idx:]
    print(f"{head} {ann}{tail}")
PYEOF
}

# Elimina la anotación 🔒 de una línea (con su espacio previo).
strip_claim_annotation() {
  printf '%s\n' "$1" | sed -E 's/ ?`🔒 [^`]*`//'
}

# Extrae handle y ts del claim de una línea. Vacío si no.
extract_claim_handle() {
  printf '%s\n' "$1" | python3 -c '
import sys, re
m = re.search(r"`🔒 (.+?) · [0-9]{4}-[0-9]{2}-[0-9]{2}", sys.stdin.read())
print(m.group(1).strip() if m else "")
' 2>/dev/null
}
extract_claim_ts() {
  printf '%s\n' "$1" | python3 -c '
import sys, re
m = re.search(r"`🔒 [^·]*· ([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2})", sys.stdin.read())
print(m.group(1) if m else "")
' 2>/dev/null
}

# Lista todos los claims activos: TSV X.Y\thandle\tts
# Usa python para parseo UTF-8 robusto (awk de macOS confunde bytes y chars con 🔒/·).
list_claims_in() {
  local f="$1"
  [ -f "$f" ] || return 0
  python3 - "$f" <<'PYEOF' 2>/dev/null
import sys, re
path = sys.argv[1]
pat_line = re.compile(r"^- \[>\] ([0-9]+\.[0-9]+)\b")
pat_claim = re.compile(r"`🔒 (.+?) · ([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2})`")
with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        m_l = pat_line.match(line)
        if not m_l:
            continue
        xy = m_l.group(1)
        m_c = pat_claim.search(line)
        if not m_c:
            continue
        handle = m_c.group(1).strip()
        ts = m_c.group(2)
        print(f"{xy}\t{handle}\t{ts}")
PYEOF
}

# --- worktree handling ---
prepare_worktree() {
  WT="$root/.git/milestone-sync-wt"
  if [ -d "$WT" ] && git -C "$WT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$WT" fetch -q origin "$branch" 2>/dev/null || true
    git -C "$WT" reset -q --hard "origin/$branch" 2>/dev/null
    git -C "$WT" clean -qfd 2>/dev/null || true
  else
    git -C "$root" worktree prune 2>/dev/null || true
    rm -rf "$WT"
    git -C "$root" worktree add -q --no-checkout "$WT" "origin/$branch" 2>/dev/null || { log "no se pudo crear worktree"; return 1; }
    git -C "$WT" sparse-checkout init --cone 2>/dev/null || true
    git -C "$WT" sparse-checkout set "$path" 2>/dev/null || true
    git -C "$WT" checkout -q 2>/dev/null || true
  fi
  return 0
}
wt_file() { printf '%s\n' "$WT/$file_rel"; }

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

  claims)
    [ "$have_remote" = 1 ] || noop "no-change"
    list_claims_in "$remote_tmp"
    exit 0 ;;

  stale)
    hours="${4:-24}"
    [ "$have_remote" = 1 ] || noop "no-change"
    now="$(date +%s)"
    list_claims_in "$remote_tmp" | while IFS=$'\t' read -r xy h ts; do
      [ -n "$ts" ] || continue
      claim_epoch="$(date -j -f "%Y-%m-%d %H:%M" "$ts" +%s 2>/dev/null || date -d "$ts" +%s 2>/dev/null)"
      [ -n "$claim_epoch" ] || continue
      age_h=$(( (now - claim_epoch) / 3600 ))
      [ "$age_h" -ge "$hours" ] && printf '%s\t%s\t%s\n' "$xy" "$h" "$age_h"
    done
    exit 0 ;;

  claim)
    xy="${4:-}"
    [ -n "$xy" ] || { log "claim: falta <X.Y>"; noop "bad-args"; }
    [ "$fetch_ok" = "1" ] || { log "claim: fetch de origin/$branch falló — sin verificación en vivo no se puede claimear (sin red? sin permisos?). Vuelve a intentarlo cuando tengas conexión."; noop "fetch-failed"; }
    [ "$have_remote" = 1 ] || { log "claim necesita el milestone publicado en $branch"; noop "no-remote-file"; }

    cur_line="$(find_subtask_line "$remote_tmp" "$xy")"
    if [ -z "$cur_line" ]; then
      log "claim: no encuentro la subtarea $xy en origin/$branch"
      echo "not-claimable:not-found"; exit 0
    fi
    state="$(printf '%s' "$cur_line" | cut -c4)"
    case "$state" in
      ' ')
        ;;
      '>')
        existing_h="$(extract_claim_handle "$cur_line")"
        log "claim: $xy ya está [>] (claimer: ${existing_h:-desconocido})"
        echo "already-claimed:${existing_h:-unknown}"; exit 0 ;;
      '~'|'x'|'-')
        log "claim: $xy está en [$state] — no claimable"
        echo "not-claimable:[$state]"; exit 0 ;;
      *)
        log "claim: estado desconocido [$state] en $xy"
        echo "not-claimable:[$state]"; exit 0 ;;
    esac

    handle="$(user_handle)"
    ts="$(date '+%Y-%m-%d %H:%M')"

    # Construir nueva línea: cambiar "- [ ]" → "- [>]" y añadir anotación.
    promoted="$(printf '%s\n' "$cur_line" | sed -E 's/^- \[ \] /- [>] /')"
    new_line="$(inject_claim_annotation "$promoted" "$handle" "$ts")"

    prepare_worktree || noop "worktree-failed"
    git -C "$WT" fetch -q origin "$branch" 2>/dev/null || true
    git -C "$WT" reset -q --hard "origin/$branch" 2>/dev/null

    wt_path="$(wt_file)"
    [ -f "$wt_path" ] || { log "claim: el archivo no está en la rama canónica"; noop "no-remote-file"; }
    cur_line_wt="$(find_subtask_line "$wt_path" "$xy")"
    state_wt="$(printf '%s' "$cur_line_wt" | cut -c4)"
    if [ "$state_wt" != " " ]; then
      lost_h="$(extract_claim_handle "$cur_line_wt")"
      log "claim: race-lost — alguien claimeó $xy mientras preparabas (claimer: ${lost_h:-desconocido})"
      echo "race-lost:${lost_h:-unknown}"; exit 0
    fi

    if ! replace_subtask_line "$wt_path" "$xy" "$new_line"; then
      log "claim: no se pudo reemplazar la línea (no encontrada tras prep)"
      noop "race-vanished"
    fi

    gid_e="$(git -C "$root" config user.email 2>/dev/null)"; [ -n "$gid_e" ] || gid_e="milestone-sync@local"
    gid_n="$(git -C "$root" config user.name 2>/dev/null)"; [ -n "$gid_n" ] || gid_n="milestone-sync"
    msg="chore(milestone): claim $slug $xy by $handle [skip ci]"
    git -C "$WT" add -- "$file_rel" 2>/dev/null
    if git -C "$WT" diff --cached --quiet -- "$file_rel" 2>/dev/null; then
      log "claim: el diff quedó vacío (algo raro)"; noop "no-change"
    fi
    git -C "$WT" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || { log "claim: commit falló"; noop "commit-failed"; }

    if git -C "$WT" push -q origin "HEAD:$branch" 2>/dev/null; then
      :
    else
      log "claim: push perdió FF; rebase y reintento"
      git -C "$WT" fetch -q origin "$branch" 2>/dev/null || true
      git -C "$WT" reset -q --hard "origin/$branch" 2>/dev/null
      cur_line_wt2="$(find_subtask_line "$wt_path" "$xy")"
      state_wt2="$(printf '%s' "$cur_line_wt2" | cut -c4)"
      if [ "$state_wt2" != " " ]; then
        lost_h2="$(extract_claim_handle "$cur_line_wt2")"
        log "claim: race-lost tras rebase — claimer: ${lost_h2:-desconocido}"
        echo "race-lost:${lost_h2:-unknown}"; exit 0
      fi
      replace_subtask_line "$wt_path" "$xy" "$new_line" || noop "race-vanished"
      git -C "$WT" add -- "$file_rel"
      git -C "$WT" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || noop "commit-failed"
      if ! git -C "$WT" push -q origin "HEAD:$branch" 2>/dev/null; then
        echo "commit-pending-push:git -C $WT push origin HEAD:$branch"; exit 0
      fi
    fi

    if [ -f "$local_file" ]; then replace_subtask_line "$local_file" "$xy" "$new_line" >/dev/null 2>&1 || true; fi

    log "claim: $xy → [>] por $handle ($ts)"
    echo "claimed" ;;

  release)
    xy="${4:-}"; force="${5:-}"
    [ -n "$xy" ] || { log "release: falta <X.Y>"; noop "bad-args"; }
    [ "$have_remote" = 1 ] || noop "no-remote-file"

    cur_line="$(find_subtask_line "$remote_tmp" "$xy")"
    [ -n "$cur_line" ] || { log "release: $xy no existe en $branch"; noop "not-found"; }
    state="$(printf '%s' "$cur_line" | cut -c4)"
    if [ "$state" != ">" ]; then
      log "release: $xy no está [>] (está [$state])"
      echo "not-claimed"; exit 0
    fi
    existing_h="$(extract_claim_handle "$cur_line")"
    handle="$(user_handle)"
    if [ "$existing_h" != "$handle" ] && [ "$force" != "--force" ]; then
      log "release: $xy lo tiene $existing_h, no tú ($handle). Usa --force si es necesario."
      echo "not-claimer:$existing_h"; exit 0
    fi

    stripped="$(strip_claim_annotation "$cur_line")"
    new_line="$(printf '%s\n' "$stripped" | sed -E 's/^- \[>\] /- [ ] /')"

    prepare_worktree || noop "worktree-failed"
    git -C "$WT" fetch -q origin "$branch" 2>/dev/null || true
    git -C "$WT" reset -q --hard "origin/$branch" 2>/dev/null
    wt_path="$(wt_file)"
    replace_subtask_line "$wt_path" "$xy" "$new_line" || noop "race-vanished"

    gid_e="$(git -C "$root" config user.email 2>/dev/null)"; [ -n "$gid_e" ] || gid_e="milestone-sync@local"
    gid_n="$(git -C "$root" config user.name 2>/dev/null)"; [ -n "$gid_n" ] || gid_n="milestone-sync"
    msg="chore(milestone): release $slug $xy by $handle [skip ci]"
    git -C "$WT" add -- "$file_rel" 2>/dev/null
    git -C "$WT" diff --cached --quiet -- "$file_rel" 2>/dev/null && noop "no-change"
    git -C "$WT" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || noop "commit-failed"
    if ! git -C "$WT" push -q origin "HEAD:$branch" 2>/dev/null; then
      echo "commit-pending-push:git -C $WT push origin HEAD:$branch"; exit 0
    fi

    if [ -f "$local_file" ]; then replace_subtask_line "$local_file" "$xy" "$new_line" >/dev/null 2>&1 || true; fi

    log "release: $xy liberada"
    echo "released" ;;

  stamp)
    xy="${4:-}"; pr="${5:-}"
    [ -n "$xy" ] && [ -n "$pr" ] || { log "stamp: faltan <X.Y> <pr>"; noop "bad-args"; }
    [ -f "$local_file" ] || noop "no-change"
    cur_line="$(find_subtask_line "$local_file" "$xy")"
    [ -n "$cur_line" ] || { log "stamp: subtarea $xy no encontrada"; noop "not-found"; }
    state="$(printf '%s' "$cur_line" | cut -c4)"
    if [ "$state" != "~" ]; then
      log "stamp: $xy está en [$state]; promover a [~] antes de sellar"
      noop "subtask-not-tilde"
    fi
    if printf '%s' "$cur_line" | grep -q "PR #${pr}"; then
      log "stamp: ya sellada con PR #${pr}"; noop "already-stamped"
    fi
    new_line="$(printf '%s `⏳ PR #%s`' "$cur_line" "$pr")"
    replace_subtask_line "$local_file" "$xy" "$new_line" || noop "not-found"
    log "stamp: $xy → PR #$pr"
    exec "$0" push "$root" "$slug" ;;

  push)
    [ -f "$local_file" ] || noop "no-change"
    if [ "$have_remote" = 1 ] && diff -q "$local_file" "$remote_tmp" >/dev/null 2>&1; then noop "no-change"; fi
    s="$(status)"
    if [ "$s" = "diverged" ] || [ "$s" = "remote-newer" ]; then
      log "DIVERGENCIA con origin/$branch — no se fuerza. Haz 'pull' y reconcilia ## Contexto."
      echo "commit-pending-push:git -C $root <reconciliar manualmente; ver git-sync.md §9>"
      exit 0
    fi
    gid_e="$(git -C "$root" config user.email 2>/dev/null)"; [ -n "$gid_e" ] || gid_e="milestone-sync@local"
    gid_n="$(git -C "$root" config user.name 2>/dev/null)"; [ -n "$gid_n" ] || gid_n="milestone-sync"
    msg="chore(milestone): sync $slug [skip ci]"
    cur="$(git -C "$root" branch --show-current 2>/dev/null)"

    if [ "$cur" = "$branch" ]; then
      git -C "$root" add -- "$file_rel" 2>/dev/null
      git -C "$root" diff --cached --quiet -- "$file_rel" 2>/dev/null && noop "no-change"
      git -C "$root" -c user.email="$gid_e" -c user.name="$gid_n" commit -q -m "$msg" -- "$file_rel" || { log "commit falló"; noop "commit-failed"; }
      if git -C "$root" push -q origin "$branch" 2>/dev/null; then echo "pushed"
      else echo "commit-pending-push:git -C $root push origin $branch"; fi
      exit 0
    fi

    prepare_worktree || noop "worktree-failed"
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
