#!/bin/bash
# Claude Code — Local usage logger
# Hook PostToolUse: se ejecuta tras cada herramienta. Recibe JSON por stdin.

LOG_FILE="$HOME/.claude/usage.jsonl"
PROJECTS_FILE="$HOME/.claude/usage-projects.json"

INPUT=$(cat)

PARSED=$(echo "$INPUT" | python3 -c "
import sys, json, os, re

data = sys.stdin.read()
try:
    d = json.loads(data)
except:
    d = {}

tool_name       = d.get('tool_name', 'unknown')
inp             = d.get('tool_input', {})
tool_input      = json.dumps(inp)
tool_output     = json.dumps(d.get('tool_response', d.get('tool_output', '')))
transcript_path = d.get('transcript_path', '')

# Extraer último mensaje del usuario desde el transcript
last_request = ''
if transcript_path and os.path.isfile(transcript_path):
    try:
        with open(transcript_path) as tf:
            lines = [l.strip() for l in tf if l.strip()]
        for line in reversed(lines):
            try:
                entry = json.loads(line)
                if entry.get('type') != 'user':
                    continue
                msg = entry.get('message', {})
                if msg.get('role') != 'user':
                    continue
                content = msg.get('content', '')
                texts = []
                if isinstance(content, list):
                    for part in content:
                        if isinstance(part, dict) and part.get('type') == 'text':
                            texts.append(part.get('text', ''))
                elif isinstance(content, str):
                    texts.append(content)
                # Unir y limpiar tags de sistema
                full = ' '.join(texts)
                full = re.sub(r'<[^>]+>.*?</[^>]+>', '', full, flags=re.DOTALL)
                full = full.strip()
                if full:
                    last_request = full[:120]
                    break
            except:
                pass
    except:
        pass

# Etiqueta descriptiva
def short(s, n=70):
    s = str(s).strip().replace('\n', ' ').replace('|||', '/')
    return s[:n] + '...' if len(s) > n else s

if tool_name == 'Bash':
    label = short(inp.get('command', ''))
elif tool_name == 'Read':
    label = os.path.basename(inp.get('file_path', '?'))
elif tool_name in ('Write', 'Edit'):
    label = os.path.basename(inp.get('file_path', '?'))
elif tool_name == 'Grep':
    pattern = inp.get('pattern', '?')
    path    = inp.get('path', inp.get('glob', ''))
    label   = f'{short(pattern, 40)} en {os.path.basename(path) if path else \"*\"}'
elif tool_name == 'Glob':
    label = inp.get('pattern', '?')
elif tool_name == 'Agent':
    label = short(inp.get('description', inp.get('prompt', '?')), 70)
elif tool_name == 'WebFetch':
    label = short(inp.get('url', '?'), 70)
elif tool_name == 'WebSearch':
    label = short(inp.get('query', '?'), 70)
elif tool_name == 'TodoWrite':
    todos = inp.get('todos', [])
    label = f'Tareas: {len(todos)} items'
elif tool_name == 'Skill':
    label = inp.get('skill', '?')
else:
    label = next((short(v) for v in inp.values() if isinstance(v, str)), '—')

# Estimación tokens
est_input  = max(1, len(tool_input)  // 4)
est_output = max(1, len(tool_output) // 4)
est_total  = est_input + est_output

req_escaped = last_request.replace('|||', '/')
print(f'{tool_name}|||{label}|||{est_input}|||{est_output}|||{est_total}|||{req_escaped}')
")

TOOL_NAME=$(echo "$PARSED" | awk -F'[|][|][|]' '{print $1}')
LABEL=$(echo "$PARSED"     | awk -F'[|][|][|]' '{print $2}')
EST_IN=$(echo "$PARSED"    | awk -F'[|][|][|]' '{print $3}')
EST_OUT=$(echo "$PARSED"   | awk -F'[|][|][|]' '{print $4}')
EST_TOT=$(echo "$PARSED"   | awk -F'[|][|][|]' '{print $5}')
REQUEST=$(echo "$PARSED"   | awk -F'[|][|][|]' '{print $6}')

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT_PATH="$PWD"

PROJECT=$(python3 -c "
import json, os, sys
path = '$PROJECT_PATH'
pfile = os.path.expanduser('$PROJECTS_FILE')
try:
    mapping = json.load(open(pfile))
    match = ''
    name  = ''
    for k, v in mapping.items():
        if path.startswith(k) and len(k) > len(match):
            match = k
            name  = v
    print(name if name else os.path.basename(path))
except:
    print(os.path.basename(path))
" 2>/dev/null || basename "$PROJECT_PATH")

SESSION_ID="${CLAUDE_SESSION_ID:-ppid_$$_$PPID}"

# Modelo activo desde settings.json
MODEL=$(python3 -c "
import json, os
try:
    d = json.load(open(os.path.expanduser('~/.claude/settings.json')))
    print(d.get('model', 'sonnet'))
except:
    print('sonnet')
" 2>/dev/null || echo "sonnet")

LABEL_JSON=$(echo "$LABEL" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")
REQUEST_JSON=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")

printf '{"ts":"%s","session":"%s","project":"%s","path":"%s","tool":"%s","model":"%s","label":%s,"request":%s,"tok_in":%s,"tok_out":%s,"tok_total":%s}\n' \
  "$TIMESTAMP" \
  "$SESSION_ID" \
  "$PROJECT" \
  "$PROJECT_PATH" \
  "$TOOL_NAME" \
  "$MODEL" \
  "$LABEL_JSON" \
  "$REQUEST_JSON" \
  "$EST_IN" \
  "$EST_OUT" \
  "$EST_TOT" >> "$LOG_FILE"
