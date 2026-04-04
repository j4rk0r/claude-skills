# Static Pattern Reference — Layer 2

Comprehensive lists for grep/regex scanning across SKILL.md and ALL bundled files. Report every match with file:line.

## Network Indicators

- Hardcoded URLs, IP addresses (especially raw IPs like `45.33.12.8`)
- Webhook endpoints: `hooks.slack.com`, `n8n`, `zapier`, custom URLs
- Network commands: `curl`, `wget`, `fetch`, `http.get`, `requests.post`, `requests.get`
- Raw connections: `/dev/tcp`, socket references, `nc`, `netcat`, `ncat`
- Server listeners: `http.server`, `HTTPServer`, `express()`, `listen(`

## Sensitive File Paths

- Credentials: `~/.ssh/`, `~/.aws/`, `~/.gnupg/`, `~/.config/gcloud/`
- Claude config: `~/.claude/`, `~/.mcp.json`, `.claude/settings.json`
- Secrets: `.env`, `.env.local`, `credentials`, `secrets.json`, `secrets.yaml`
- Tokens: `~/.gitconfig`, `~/.netrc`, `~/.npmrc` (contain auth tokens)
- Shell config: `~/.bashrc`, `~/.zshrc`, `~/.profile` (persistence vector)
- System: `/etc/passwd`, `/etc/shadow`, `/etc/hosts`

## Dangerous Commands

- Execution: `eval`, `exec`, `source`, `sh -c`, `bash -c`
- Destruction: `rm -rf`, `chmod 777`, `chown`
- Obfuscation: `base64 --decode`, `xxd`, `od`, `openssl enc`
- Installation: `pip install`, `npm install`, `brew install` (undeclared deps)
- Git: `git push`, `git remote add`, `git commit` (repo modification)
- Persistence: `crontab`, `launchctl`, `systemctl`, `at`
- Redirection: `>> ~/.bashrc`, `>> ~/.zshrc` (shell persistence)
- Kill: `kill`, `pkill`, `killall`

## Environment Variables

- Specific: `$GITHUB_TOKEN`, `$GH_TOKEN`, `$ANTHROPIC_API_KEY`, `$AWS_SECRET_ACCESS_KEY`, `$NPM_TOKEN`, `$OPENAI_API_KEY`
- Patterns: `$*_KEY`, `$*_TOKEN`, `$*_SECRET`, `$*_PASSWORD`
- Python: `os.environ`, `os.getenv`
- Node: `process.env`

## Obfuscation Signals

- Base64 strings longer than 20 characters
- Hex sequences: `\x41\x42...`
- Unicode escapes: `\u0041...`
- Invisible unicode: zero-width space (U+200B), zero-width joiner (U+200D), RTL override (U+202E), BOM (U+FEFF)
- Homoglyphs: cyrillic `а` (U+0430) vs latin `a` (U+0061) — visually identical but different characters

## Dangerous Imports by Language

### Python
`subprocess`, `os.system`, `shutil.rmtree`, `socket`, `http.client`, `urllib`, `requests`, `smtplib`, `ftplib`, `paramiko`

### Node
`child_process`, `net`, `http`, `https`, `dgram`, `fs` (with paths outside project)

### Bash
Calls to `curl`, `wget`, `nc`, `ssh`, `scp`, `rsync` (to external hosts)

## False Positive Guidance

Not everything that matches is malicious. Use context:

| Pattern | Suspicious when... | Legitimate when... |
|---------|-------------------|-------------------|
| `base64` | Decoding hardcoded strings + `eval()` | Encoding images as data URIs for HTML |
| `subprocess` | Combined with network calls or env var access | Running local CLI tools (like `claude -p`) |
| `http.server` | Listening on 0.0.0.0 or public ports | Serving localhost-only for local viewer |
| `os.environ` | Reading `$GITHUB_TOKEN`, `$AWS_*` | Removing a single env var for subprocess |
| `requests.post` | Destination is external URL or IP | Destination is localhost or documented API |
| `git push` | To a remote the user didn't configure | Part of documented workflow user consented to |
