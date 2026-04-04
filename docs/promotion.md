# Posts para promocionar skill-advisor

---

## 1. Reddit (r/ClaudeAI, r/ChatGPTPro, r/CodingWithAI)

**Title:** I built a skill that makes sure you actually USE your installed Claude Code skills

You install 50 skills. You use 5. The other 45 collect dust.

I built **skill-advisor** to fix this. It sits between you and Claude Code, analyzing every instruction to recommend the right skill from your installed collection — before any work begins.

**How it works:**

- You type "fix this login bug"
- skill-advisor scans your installed skills
- Recommends: `/systematic-debugging` + `/webapp-testing`
- You confirm, skill executes

**What makes it different:**

- Reads YOUR installed skills dynamically. No hardcoded list. Install a new skill today, it sees it tomorrow.
- Thinks laterally. "make it look better" finds design, animation, AND accessibility skills.
- Knows when to shut up. Simple tasks get no recommendations.
- Recommends full pipelines, not just single skills.
- If no local skill matches, suggests one from the community to install.

Scored 120/120 with skill-judge.

Install:
```
npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global
```

Repo: https://github.com/j4rk0r/claude-skills

Open source, MIT. Feedback welcome.

---

## 2. X / Twitter

**Post 1 (hook):**

You install 50 Claude Code skills.
You use 5.
The other 45 collect dust.

I built skill-advisor to fix this.

It reads your installed skills and recommends the right one before every task.

No hardcoded list. No config. Just works.

npx skills add j4rk0r/claude-skills --skill skill-advisor -yg

github.com/j4rk0r/claude-skills

**Post 2 (thread):**

How skill-advisor works:

1/ You type an instruction
2/ It scans your installed skills (from system-reminder)
3/ Matches your intent to skill descriptions
4/ Recommends 1-5, ranked by impact
5/ You confirm or skip

Pre-action: recommends before you start
Post-action: suggests next steps after you finish

It thinks laterally:
"make it look better" -> finds design + animation + accessibility skills

It knows when to shut up:
Simple tasks? No recommendation. Moving fast? Won't interrupt.

120/120 on skill-judge. Open source.

---

## 3. Anthropic Discord / Claude Code community

**Title:** skill-advisor — stop forgetting your installed skills

Hey everyone. I had a problem: I installed 50+ skills but only remembered to use 5-6 of them regularly.

So I built **skill-advisor** — a meta-skill that acts as a routing brain for your skill ecosystem.

**What it does:**
- Before every task: scans your installed skills and recommends the best match
- After every task: suggests the logical next step (testing, commit, review...)
- First run: scans your ecosystem and reports what you have

**Key design decisions:**
- Zero hardcoded skill references. It reads from your system-reminder dynamically, so it works with ANY skill set.
- Intent matching by skill description keywords, not literal name matching.
- Anti-annoyance built in: won't interrupt simple tasks, won't repeat rejected suggestions.
- Fallback: if nothing local matches, suggests community skills to install.

**Quality:** Evaluated with skill-judge, scored 120/120 across all 8 dimensions.

**Install:**
```
npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global
```

Available in 7 languages (EN, ES, FR, DE, PT, ZH, JA).

Would love feedback. What would you add?

---

## 4. GitHub Discussions / Issues (en repos populares de skills)

**Title:** [Suggestion] skill-advisor — meta-skill for skill discovery

Hi! I built a meta-skill that helps users discover and use their installed skills more effectively.

**Problem:** Most users install many skills but forget to use them because there's no recommendation system.

**Solution:** skill-advisor analyzes every instruction and recommends the right installed skill before execution.

- Dynamic: reads from system-reminder, no hardcoded lists
- Universal: works with any skill set
- Non-intrusive: knows when NOT to recommend

Available at: https://github.com/j4rk0r/claude-skills

Would be happy to contribute this to the official collection if there's interest.

---

## 5. LinkedIn (professional audience)

I solved a UX problem in AI-assisted development.

Claude Code has a skill ecosystem with 70+ installable skills. The problem: developers install dozens but only remember to use a handful.

I built skill-advisor — a meta-skill that acts as a routing brain. It analyzes every instruction you give and recommends the most relevant installed skill before execution begins.

Key design principles:
- Dynamic discovery (no hardcoded catalogs)
- Lateral intent matching (not just keyword lookup)
- Anti-annoyance calibration (knows when to be silent)
- Pipeline detection (recommends multi-step combos)

Scored 120/120 on the skill-judge evaluation framework.

Open source: github.com/j4rk0r/claude-skills
Install: npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global

#ClaudeCode #DeveloperTools #AI #OpenSource
