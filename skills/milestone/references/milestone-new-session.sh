#!/bin/bash
# Abre una nueva ventana de Claude con el contexto compacto de un milestone.
# Uso: ~/.claude/milestone-new-session.sh <project-root> <milestone-slug>
# Ejemplo: ~/.claude/milestone-new-session.sh /Applications/docker/Oltex dashboard-propietario

PROJECT_ROOT="${1:-$(pwd)}"
SLUG="$2"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"

if [ -z "$SLUG" ]; then
  echo "Error: falta el nombre del milestone."
  echo "Uso: milestone-new-session.sh <project-root> <milestone-slug>"
  exit 1
fi

# Fuzzy match: acepta slug parcial
MILESTONE_FILE=""
for f in "$PROJECT_ROOT/.milestones/"*.md; do
  basename_f=$(basename "$f" .md)
  if [[ "$basename_f" == "$SLUG" || "$basename_f" == *"$SLUG"* ]]; then
    MILESTONE_FILE="$f"
    SLUG=$(basename "$f" .md)
    break
  fi
done

if [ -z "$MILESTONE_FILE" ] || [ ! -f "$MILESTONE_FILE" ]; then
  echo "Milestone no encontrado: $SLUG"
  echo "Disponibles:"
  ls "$PROJECT_ROOT/.milestones/"*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md//'
  exit 1
fi

# Generar contexto compacto (solo lo esencial, sin historial)
TMPFILE=$(mktemp /tmp/milestone-context-XXXXXX.txt)
trap "rm -f '$TMPFILE'" EXIT

python3 << PYEOF > "$TMPFILE"
import re

with open("$MILESTONE_FILE") as f:
    content = f.read()

name_match = re.search(r'name:\s*"([^"]+)"', content)
name = name_match.group(1) if name_match else "$SLUG"

status_match = re.search(r'status:\s*(\S+)', content)
status = status_match.group(1) if status_match else "?"

obj_match = re.search(r'## Objetivo\n(.*?)(?=\n##)', content, re.DOTALL)
objetivo = obj_match.group(1).strip()[:500] if obj_match else "(sin objetivo)"

pending = re.findall(r'- \[ \] .+', content)
done = re.findall(r'- \[x\] .+', content, re.IGNORECASE)

# Solo la entrada de contexto más reciente
ctx_entries = re.findall(r'(### \d{4}-\d{2}-\d{2}[^\n]*\n(?:(?!###).*\n?)*)', content)
last_ctx = ctx_entries[0].strip() if ctx_entries else ""
last_ctx_lines = last_ctx.split('\n')[:6]

refs = re.findall(r'- \`([^`]+)\`', content)

lines = [
    f"# Milestone: {name} [{len(done)}/{len(done)+len(pending)} subtareas | {status}]",
    "",
    "## Objetivo",
    objetivo,
    "",
]

if pending:
    lines.append("## Pendiente")
    for t in pending[:12]:
        lines.append(t)
    lines.append("")

if last_ctx_lines:
    lines.append("## Último contexto registrado")
    lines.extend(last_ctx_lines)
    lines.append("")

if refs:
    lines.append("## Archivos clave (referencias)")
    for r in refs[:10]:
        lines.append(f"  - {r}")
    lines.append("")

lines.append("---")
lines.append("Sesión nueva — sin historial previo acumulado. Resume el trabajo desde el estado anterior.")

print('\n'.join(lines))
PYEOF

SESSION_NAME="ms-$SLUG"
CONTEXT=$(cat "$TMPFILE")

# Escapar comillas simples para uso seguro en AppleScript
CONTEXT_ESCAPED="${CONTEXT//\\/\\\\}"
CONTEXT_ESCAPED="${CONTEXT_ESCAPED//\"/\\\"}"

CMD="cd '$PROJECT_ROOT' && '$CLAUDE_BIN' --name '$SESSION_NAME' \"$CONTEXT_ESCAPED\""

echo "Abriendo nueva sesión: $SESSION_NAME"
echo "Proyecto: $PROJECT_ROOT"
echo "Milestone: $MILESTONE_FILE"
echo ""

# Detectar terminal disponible y abrir nueva ventana
if osascript -e 'tell application "iTerm2" to get name' &>/dev/null 2>&1; then
  # iTerm2
  osascript << APPLESCRIPT
tell application "iTerm2"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "$CMD"
    end tell
end tell
APPLESCRIPT
elif osascript -e 'tell application "Terminal" to get name' &>/dev/null 2>&1; then
  # Terminal.app
  osascript << APPLESCRIPT
tell application "Terminal"
    activate
    do script "$CMD"
end tell
APPLESCRIPT
else
  echo "No se encontró iTerm2 ni Terminal.app."
  echo "Ejecuta manualmente en una nueva ventana:"
  echo ""
  echo "  $CMD"
  exit 1
fi
