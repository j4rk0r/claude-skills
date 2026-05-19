#!/bin/bash
# Claude Code — Context Guard (PreToolUse)
# Red de seguridad: avisa cuando la conversacion acumula demasiados tool calls.
# Con la regla "1 subtarea = 1 ventana", estos umbrales solo se activan
# si una subtarea individual se alarga mas de lo esperado.
#
# Umbrales:
#   20 calls → aviso suave (stdout, exit 0)
#   40 calls → aviso fuerte (stdout, exit 0)
#   Solo avisa una vez por umbral para no añadir ruido.
#
# Exit codes:
#   0 = permitir siempre (nunca bloquea, solo informa)

COUNTER_DIR="/tmp/claude-context-guard"
mkdir -p "$COUNTER_DIR"

# Identificar sesion: CLAUDE_SESSION_ID o PPID
SESSION_KEY="${CLAUDE_SESSION_ID:-ppid_$$_$PPID}"
SESSION_HASH=$(echo -n "$SESSION_KEY" | shasum -a 256 | cut -c1-12)
COUNTER_FILE="$COUNTER_DIR/$SESSION_HASH"

# Limpiar sesiones >4h
find "$COUNTER_DIR" -type f -mmin +240 -delete 2>/dev/null

# Leer e incrementar
COUNT=0
WARNED_20=0
WARNED_40=0
if [ -f "$COUNTER_FILE" ]; then
    COUNT=$(head -1 "$COUNTER_FILE" 2>/dev/null || echo 0)
    WARNED_20=$(sed -n '2p' "$COUNTER_FILE" 2>/dev/null || echo 0)
    WARNED_40=$(sed -n '3p' "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))

# Guardar estado (count, warned_20, warned_40)
save_state() {
    printf '%s\n%s\n%s\n' "$COUNT" "$WARNED_20" "$WARNED_40" > "$COUNTER_FILE"
}

# Umbral 40: aviso fuerte
if [ "$COUNT" -ge 40 ] && [ "$WARNED_40" -eq 0 ]; then
    WARNED_40=1
    save_state
    cat << 'MSG'
AVISO DE CONTEXTO CRITICO: Esta conversacion lleva 40+ tool calls. El contexto acumulado hace que CADA tool call cueste 2-3x mas que en una conversacion nueva. Debes:
1. Terminar lo que tengas entre manos (maximo 2-3 tools mas)
2. Guardar el estado actual con /milestone update
3. Abrir una nueva sesion con /milestone start <nombre>
4. Explicar al usuario que continuaras con todo el contexto intacto pero sin el overhead acumulado
MSG
    exit 0
fi

# Umbral 20: aviso suave
if [ "$COUNT" -ge 20 ] && [ "$WARNED_20" -eq 0 ]; then
    WARNED_20=1
    save_state
    cat << 'MSG'
AVISO DE CONTEXTO: Esta conversacion lleva 20+ tool calls. El coste por operacion empieza a inflarse por contexto acumulado. Cuando termines la tarea actual, abre una nueva sesion con /milestone start para la siguiente subtarea.
MSG
    exit 0
fi

save_state
exit 0
