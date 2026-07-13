#!/usr/bin/env bash
# team-bootstrap.sh — alta de un miembro del equipo en el modo central de milestone.
#
# Deja la máquina de un developer lista para trabajar con milestones en modo
# central (git-sync.md §2b): clona/actualiza el repo central de memorias en
# ~/.claude/projects, instala la skill milestone y el helper de sync, y
# verifica la identidad git que firmará los claims (R14).
#
# Uso:
#   CENTRAL_REPO_URL=<url-del-repo-central> bash team-bootstrap.sh
#   bash team-bootstrap.sh <url-del-repo-central>
#
# Variables de entorno:
#   CENTRAL_REPO_URL   URL del repo central de memorias del equipo (OBLIGATORIA;
#                      también aceptada como primer argumento posicional)
#   CENTRAL_ROOT       destino local del clone (default: ~/.claude/projects)
#   SKILLS_REPO_URL    repo con las skills (para instalar milestone si falta)
#                      (default: vacío — si la skill falta, se avisa y se indica el paso manual)
set -o pipefail

CENTRAL_REPO_URL="${CENTRAL_REPO_URL:-${1:-}}"
if [ -z "$CENTRAL_REPO_URL" ]; then
  printf '❌ Falta CENTRAL_REPO_URL (la URL del repo central de memorias de tu equipo).\n' >&2
  printf '   Uso: CENTRAL_REPO_URL=<url> bash team-bootstrap.sh  |  bash team-bootstrap.sh <url>\n' >&2
  exit 1
fi
CENTRAL_ROOT="${CENTRAL_ROOT:-$HOME/.claude/projects}"
SKILLS_REPO_URL="${SKILLS_REPO_URL:-}"
SKILL_DIR="$HOME/.claude/skills/milestone"
HELPER_DST="$HOME/.claude/milestone-sync.sh"

ok()   { printf '  ✅ %s\n' "$*"; }
warn() { printf '  ⚠️  %s\n' "$*"; }
fail() { printf '  ❌ %s\n' "$*"; }

echo "== 1/4 · Repo central de memorias =="
if [ -d "$CENTRAL_ROOT/.git" ] || git -C "$CENTRAL_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  current_url="$(git -C "$CENTRAL_ROOT" remote get-url origin 2>/dev/null)"
  if [ -n "$current_url" ]; then
    git -C "$CENTRAL_ROOT" fetch -q origin 2>/dev/null && ok "repo central actualizado ($current_url)" \
      || warn "fetch falló — revisa red/credenciales ($current_url)"
    git -C "$CENTRAL_ROOT" pull -q --ff-only 2>/dev/null || warn "pull --ff-only no aplicado (¿cambios locales?); resuélvelo a mano"
  else
    warn "$CENTRAL_ROOT es git pero sin remote origin — añade: git -C '$CENTRAL_ROOT' remote add origin $CENTRAL_REPO_URL"
  fi
elif [ -d "$CENTRAL_ROOT" ] && [ -n "$(ls -A "$CENTRAL_ROOT" 2>/dev/null)" ]; then
  # Directorio existente NO-git (instalación previa de Claude Code con transcripts):
  # convertirlo en clone sin perder contenido — init + fetch + checkout de main.
  echo "  $CENTRAL_ROOT existe sin git — inicializando in-place (no se borra nada)"
  git -C "$CENTRAL_ROOT" init -q \
    && git -C "$CENTRAL_ROOT" remote add origin "$CENTRAL_REPO_URL" \
    && git -C "$CENTRAL_ROOT" fetch -q origin \
    && default_branch="$(git -C "$CENTRAL_ROOT" remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/{print $2; exit}')" \
    && git -C "$CENTRAL_ROOT" checkout -q -b "${default_branch:-main}" "origin/${default_branch:-main}" 2>/dev/null
  if git -C "$CENTRAL_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -n "$(git -C "$CENTRAL_ROOT" branch --show-current 2>/dev/null)" ]; then
    ok "repo central inicializado in-place en $CENTRAL_ROOT"
  else
    fail "no se pudo inicializar in-place (¿conflictos con archivos locales?). Clónalo aparte y fusiona a mano: git clone $CENTRAL_REPO_URL"
  fi
else
  git clone -q "$CENTRAL_REPO_URL" "$CENTRAL_ROOT" && ok "repo central clonado en $CENTRAL_ROOT" \
    || fail "clone falló — verifica acceso a $CENTRAL_REPO_URL (gh auth login / SSH key)"
fi

echo "== 2/4 · Skill milestone =="
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  ok "skill instalada en $SKILL_DIR"
elif [ -n "$SKILLS_REPO_URL" ]; then
  tmp="$(mktemp -d)"
  if git clone -q --depth 1 "$SKILLS_REPO_URL" "$tmp" 2>/dev/null && [ -d "$tmp/skills/milestone" ]; then
    mkdir -p "$HOME/.claude/skills"
    cp -R "$tmp/skills/milestone" "$SKILL_DIR" && ok "skill instalada desde $SKILLS_REPO_URL"
  else
    fail "no se pudo instalar la skill desde $SKILLS_REPO_URL"
  fi
  rm -rf "$tmp"
else
  warn "skill no encontrada. Instálala copiando skills/milestone del repo de skills del equipo a $SKILL_DIR"
fi

echo "== 3/4 · Helper milestone-sync.sh =="
if [ -f "$SKILL_DIR/references/milestone-sync.sh" ]; then
  cp "$SKILL_DIR/references/milestone-sync.sh" "$HELPER_DST" && chmod +x "$HELPER_DST" \
    && ok "helper instalado/actualizado en $HELPER_DST"
else
  warn "references/milestone-sync.sh no disponible aún (instala la skill primero)"
fi

echo "== 4/4 · Identidad git para claims (R14) =="
gn="$(git config --global user.name 2>/dev/null)"
ge="$(git config --global user.email 2>/dev/null)"
if [ -n "$gn" ] && [ -n "$ge" ]; then
  ok "claims firmarán como: $gn (${ge%%@*})"
else
  warn "falta identidad git global — configúrala: git config --global user.name 'Tu Nombre' && git config --global user.email 'tu@email'"
fi

echo ""
echo "Listo. Para verificar un proyecto en modo central:"
echo "  ~/.claude/milestone-sync.sh check <ruta-proyecto> <slug>"
echo "  (la config debe existir en $CENTRAL_ROOT/<clave>/milestones/config.yml)"
