# skill-guard

**Security auditor for Claude Code skills.** Analyzes skills before installation using a 9-layer threat detection engine.

## The Problem

Anyone can publish a Claude Code skill. Once installed, a skill can:
- Execute arbitrary commands via Bash
- Read any file on your system (`~/.ssh`, `~/.aws`, `~/.claude`)
- Access environment variables (`$GITHUB_TOKEN`, `$AWS_SECRET_ACCESS_KEY`)
- Call MCP APIs (Slack, GitHub, Monday.com) without declaring permissions
- Spawn subagents that inherit full access

There is no code signing, no permission model enforcement, and no integrity verification.

## The Solution

skill-guard audits skills **before** you install them.

```
You: npx skills add some-cool-skill

skill-guard: This skill hasn't been audited.
             Want me to run a security analysis before installing?

You: yes

skill-guard: [runs 9-layer analysis]

══════════════════════════════════════════════════
  SKILL-GUARD — Security Report
══════════════════════════════════════════════════
  Skill:   some-cool-skill
  Score:   72/100  YELLOW
  ...
  Install anyway? [Y/N]
══════════════════════════════════════════════════
```

## Install

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

## The 9 Analysis Layers

| # | Layer | Weight | What it detects |
|---|-------|--------|----------------|
| 1 | Frontmatter & Permissions | 20% | Missing `allowed-tools`, unrestricted Bash, incoherent permissions |
| 2 | Static Patterns | 15% | Hardcoded URLs/IPs, sensitive paths, dangerous commands, env var access |
| 3 | **LLM Semantic Analysis** | **30%** | Prompt injection, trojans, social engineering, exfiltration, time bombs |
| 4 | Bundled Script Analysis | 15% | Dangerous imports, obfuscation, network calls in scripts |
| 5 | Data Flow | 10% | Sensitive source → external destination chains |
| 6 | MCP & External Tools | — | Undeclared MCP usage, exfiltration via services |
| 7 | Supply Chain | 2% | Typosquatting, unpinned versions, fake repos |
| 8 | Reputation | 3% | Author profile, repo age, community signals |
| 9 | Anti-Evasion | 5% | Unicode tricks, homoglyphs, self-modification, environment fingerprinting |

## Scoring

- **GREEN (80-100):** Safe — auto-installs
- **YELLOW (40-79):** Minor risks — you decide with full info
- **RED (0-39):** Dangerous — strong warning, you have final word

**Critical finding override:** Any single critical finding (exfiltration confirmed, credential access, prompt injection, binaries) caps the score at 39 — automatic RED.

## Community Audit Registry

Every audit is saved to `audits/` in this repo. Before analyzing a skill, skill-guard checks if it's already been audited:

```
audits/
├── index.json              ← quick lookup
└── {author}/
    └── {skill-name}/
        └── {SHA-short}.json  ← full report
```

If the SHA-256 matches a previous audit, you get instant results without re-analysis.

## First Run

On first invocation, skill-guard offers to audit all your installed skills:

```
Skill-Guard activado.

Tienes 69 skills instaladas que nunca han sido auditadas.
¿Quieres que analice la seguridad de tus skills instaladas?

  1. Auditar todas
  2. Solo las que tienen scripts bundled (mayor riesgo)
  3. Elegir cuáles
  4. Saltar
```

## Integration

skill-guard intercepts skill installations from:
- `npx skills add` commands
- `/find-skills` recommendations
- `/skill-advisor` suggestions
- Manual `/skill-guard <skill-reference>`

## License

[MIT](../LICENSE)
