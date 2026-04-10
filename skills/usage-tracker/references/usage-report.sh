#!/bin/bash
# Claude Code — Usage Report
# Uso: ~/.claude/usage-report.sh [hoy|semana|mes|all] [proyecto]

LOG_FILE="$HOME/.claude/usage.jsonl"
SPIKE_THRESHOLD=5000   # tokens por sesión para marcar como PICO

if [ ! -f "$LOG_FILE" ]; then
  echo "No hay datos de uso todavía. El log se crea automáticamente con el primer uso."
  exit 0
fi

FILTER="${1:-hoy}"
PROJECT_FILTER="${2:-}"

case "$FILTER" in
  hoy)
    SINCE=$(python3 -c "from datetime import datetime, timezone; import time; tz=datetime.now().astimezone().tzinfo; today=datetime.now(tz).replace(hour=0,minute=0,second=0,microsecond=0); print(today.astimezone(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
    LABEL="Hoy ($(date +%d/%m/%Y))"
    ;;
  semana)
    SINCE=$(date -u -v-7d +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%dT00:00:00Z")
    LABEL="Últimos 7 días"
    ;;
  mes)
    SINCE=$(date -u -v-30d +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -d "30 days ago" +"%Y-%m-%dT00:00:00Z")
    LABEL="Últimos 30 días"
    ;;
  all|*)
    SINCE="1970-01-01T00:00:00Z"
    LABEL="Todo el historial"
    ;;
esac

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "  CLAUDE CODE — REPORTE DE USO LOCAL"
echo "  Período : $LABEL"
[ -n "$PROJECT_FILTER" ] && echo "  Proyecto: $PROJECT_FILTER"
echo "╚══════════════════════════════════════════════════════════════╝"

python3 << EOF
import json, sys
from collections import defaultdict, Counter
from datetime import datetime, timezone

log_file        = "$LOG_FILE"
since           = "$SINCE"
project_filter  = "$PROJECT_FILTER"
spike_threshold = $SPIKE_THRESHOLD

# Precios por modelo (€/token)
PRICES = {
    "opus":   {"in": 0.0000138,   "out": 0.0000690},
    "sonnet": {"in": 0.00000276,  "out": 0.0000138},
    "haiku":  {"in": 0.000000736, "out": 0.00000368},
}

def cost_eur(tok_in, tok_out, model="sonnet"):
    p = PRICES.get(model, PRICES["sonnet"])
    return tok_in * p["in"] + tok_out * p["out"]

# Fallback compatibilidad con entradas antiguas sin campo model
PRICE_IN_EUR  = 0.00000276
PRICE_OUT_EUR = 0.0000138

def utc_to_local(ts_str):
    """Convierte timestamp UTC ISO a hora local HH:MM:SS"""
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.astimezone().strftime("%H:%M:%S")
    except:
        return ts_str[11:19]

entries = []
with open(log_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            if d.get("ts", "") >= since:
                if not project_filter or project_filter.lower() in d.get("project","").lower():
                    entries.append(d)
        except:
            pass

if not entries:
    print("\n  Sin registros para el período seleccionado.")
    sys.exit(0)

total_calls  = len(entries)
total_tok_in = sum(e.get("tok_in",    0) for e in entries)
total_tok_out= sum(e.get("tok_out",   0) for e in entries)
total_tokens = sum(e.get("tok_total", 0) for e in entries)
total_eur    = sum(cost_eur(e.get("tok_in",0), e.get("tok_out",0), e.get("model","sonnet")) for e in entries)

# Sesiones reales (agrupadas por session ID)
sessions_data = defaultdict(lambda: {"calls":0,"tokens":0,"tok_in":0,"tok_out":0,"project":"","ts":""})
for e in entries:
    sid = e.get("session","?")
    sessions_data[sid]["calls"]   += 1
    sessions_data[sid]["tokens"]  += e.get("tok_total", 0)
    sessions_data[sid]["tok_in"]  += e.get("tok_in",    0)
    sessions_data[sid]["tok_out"] += e.get("tok_out",   0)
    sessions_data[sid]["project"]  = e.get("project", "?")
    if e.get("ts","") > sessions_data[sid]["ts"]:
        sessions_data[sid]["ts"] = e.get("ts","")

num_sessions = len(sessions_data)
spikes = [sid for sid, v in sessions_data.items() if v["tokens"] >= spike_threshold]

print(f"""
  Herramientas ejecutadas : {total_calls}
  Sesiones únicas         : {num_sessions}
  Tokens estimados (*)    : {total_tokens:,}  (entrada: {total_tok_in:,} / salida: {total_tok_out:,})
  Coste estimado (**)     : {total_eur:.4f} €""")

if spikes:
    print(f"\n  ⚠️  PICOS detectados ({len(spikes)} sesión/es superaron {spike_threshold:,} tokens):")
    for sid in spikes:
        v = sessions_data[sid]
        print(f"     · {utc_to_local(v['ts'])} [{v['project']}]  {v['tokens']:,} tokens  {v['calls']} herramientas")

# ── Por proyecto ──
by_project = defaultdict(lambda: {"calls":0,"tokens":0,"tok_in":0,"tok_out":0,"eur":0.0})
for e in entries:
    p = e.get("project","?")
    by_project[p]["calls"]   += 1
    by_project[p]["tokens"]  += e.get("tok_total", 0)
    by_project[p]["tok_in"]  += e.get("tok_in",    0)
    by_project[p]["tok_out"] += e.get("tok_out",   0)
    by_project[p]["eur"]     += cost_eur(e.get("tok_in",0), e.get("tok_out",0), e.get("model","sonnet"))

print(f"\n  ── Por proyecto ─────────────────────────────────────────────")
print(f"  {'Proyecto':<25} {'Calls':>6}  {'Tokens':>8}  {'Modelo':>8}  {'Coste est.':>10}")
print(f"  {'-'*25} {'-'*6}  {'-'*8}  {'-'*8}  {'-'*10}")
for proj, v in sorted(by_project.items(), key=lambda x: -x[1]["eur"])[:10]:
    pct = int(v["tokens"] / total_tokens * 20) if total_tokens else 0
    bar = "█" * pct
    print(f"  {proj:<25} {v['calls']:>6}  {v['tokens']:>8,}  {'—':>8}  {v['eur']:>9.4f}€  {bar}")

# ── Por herramienta ──
by_tool = defaultdict(lambda: {"calls":0,"tokens":0,"tok_in":0,"tok_out":0,"eur":0.0})
for e in entries:
    t = e.get("tool","?")
    by_tool[t]["calls"]   += 1
    by_tool[t]["tokens"]  += e.get("tok_total", 0)
    by_tool[t]["tok_in"]  += e.get("tok_in",    0)
    by_tool[t]["tok_out"] += e.get("tok_out",   0)
    by_tool[t]["eur"]     += cost_eur(e.get("tok_in",0), e.get("tok_out",0), e.get("model","sonnet"))

print(f"\n  ── Por herramienta ──────────────────────────────────────────")
print(f"  {'Herramienta':<18} {'Calls':>6}  {'Tok.IN':>8}  {'Tok.OUT':>8}  {'Total':>8}  {'Coste':>9}")
print(f"  {'-'*18} {'-'*6}  {'-'*8}  {'-'*8}  {'-'*8}  {'-'*9}")
for tool, v in sorted(by_tool.items(), key=lambda x: -x[1]["eur"])[:15]:
    print(f"  {tool:<18} {v['calls']:>6}  {v['tok_in']:>8,}  {v['tok_out']:>8,}  {v['tokens']:>8,}  {v['eur']:>8.4f}€")

# ── Por petición ──
by_request = defaultdict(lambda: {"calls":0,"tokens":0,"tok_in":0,"tok_out":0,"eur":0.0,"tools":[],"ts":""})
for e in entries:
    req = e.get("request","").strip()
    if not req:
        req = "(sin petición)"
    key = req[:100]
    by_request[key]["calls"]   += 1
    by_request[key]["tokens"]  += e.get("tok_total", 0)
    by_request[key]["tok_in"]  += e.get("tok_in",    0)
    by_request[key]["tok_out"] += e.get("tok_out",   0)
    by_request[key]["eur"]     += cost_eur(e.get("tok_in",0), e.get("tok_out",0), e.get("model","sonnet"))
    by_request[key]["tools"].append(e.get("tool","?"))
    if e.get("ts","") > by_request[key]["ts"]:
        by_request[key]["ts"] = e.get("ts","")

print(f"\n  ── Por petición (top 20 más costosas) ───────────────────────")
print(f"  {'Hora':<8}  {'T':>3}  {'Tokens':>8}  {'Coste':>9}  Petición")
print(f"  {'-'*8}  {'-'*3}  {'-'*8}  {'-'*9}  {'-'*60}")
for req_key, v in sorted(by_request.items(), key=lambda x: -x[1]["eur"])[:20]:
    eur         = v["eur"]
    hora        = utc_to_local(v["ts"])
    tool_summary= ", ".join(f"{t}×{c}" for t, c in Counter(v["tools"]).most_common(4))
    req_display = req_key[:60] + ("…" if len(req_key) >= 60 else "")
    print(f"  {hora:<8}  {v['calls']:>3}  {v['tokens']:>8,}  {eur:>8.4f}€  {req_display}")
    print(f"           └─ [{tool_summary}]")

# ── Por sesión ──
print(f"\n  ── Por sesión ───────────────────────────────────────────────")
print(f"  {'Última acción':<8}  {'Proyecto':<20}  {'Calls':>5}  {'Tokens':>8}  {'Coste':>9}  {'Alerta'}")
print(f"  {'-'*8}  {'-'*20}  {'-'*5}  {'-'*8}  {'-'*9}  {'-'*6}")
for sid, v in sorted(sessions_data.items(), key=lambda x: -x[1]["tokens"])[:15]:
    eur   = v.get("eur", cost_eur(v["tok_in"], v["tok_out"]))
    hora  = utc_to_local(v["ts"])
    proj  = v["project"][:20]
    alerta= "⚠️ PICO" if v["tokens"] >= spike_threshold else ""
    print(f"  {hora:<8}  {proj:<20}  {v['calls']:>5}  {v['tokens']:>8,}  {eur:>8.4f}€  {alerta}")

# ── Por día ──
by_day = defaultdict(lambda: {"calls":0,"tokens":0,"tok_in":0,"tok_out":0,"eur":0.0})
for e in entries:
    day = e.get("ts","")[:10]
    by_day[day]["calls"]   += 1
    by_day[day]["tokens"]  += e.get("tok_total", 0)
    by_day[day]["tok_in"]  += e.get("tok_in",    0)
    by_day[day]["tok_out"] += e.get("tok_out",   0)
    by_day[day]["eur"]     += cost_eur(e.get("tok_in",0), e.get("tok_out",0), e.get("model","sonnet"))

print(f"\n  ── Por día ──────────────────────────────────────────────────")
print(f"  {'Día':<12}  {'Calls':>5}  {'Tokens':>8}  {'Coste est.':>10}")
print(f"  {'-'*12}  {'-'*5}  {'-'*8}  {'-'*10}")
for day in sorted(by_day.keys(), reverse=True)[:10]:
    v   = by_day[day]
    eur = v["eur"]
    bar = "█" * min(v["tokens"] // 1000 + 1, 20)
    print(f"  {day}  {v['calls']:>5}  {v['tokens']:>8,}  {eur:>9.4f}€  {bar}")

# ── Acciones recientes ──
print(f"\n  ── Acciones recientes (últimas 30) ──────────────────────────")
print(f"  {'Hora':<8}  {'Tool':<10}  {'Tok':>6}  {'Descripción':<35}  Petición")
print(f"  {'-'*8}  {'-'*10}  {'-'*6}  {'-'*35}  {'-'*50}")
recent = sorted(entries, key=lambda x: x.get("ts",""), reverse=True)[:30]
for e in recent:
    hora    = utc_to_local(e.get("ts",""))
    tool    = e.get("tool","?")[:10]
    tok     = e.get("tok_total", 0)
    label   = e.get("label", "—")[:35]
    request = e.get("request", "")[:60]
    print(f"  {hora:<8}  {tool:<10}  {tok:>6,}  {label:<35}  {request}")

print(f"""
  (*) Estimación basada en tamaño input/output (~4 chars = 1 token).
      No incluye el contexto completo de conversación enviado a la API.
 (**) Precio calculado según modelo de cada entrada (Opus/Sonnet/Haiku) usando tarifas API Anthropic.
      Claude Max es suscripción fija — el coste real no es este número.

  Log: {log_file}
""")
EOF
