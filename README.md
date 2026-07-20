# model-router

**Your frontier model thinks. Cheap open-weight models type. By default.**

An [Agent Skill](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) for **Claude Code** and **GitHub Copilot** that turns cost optimization into a standing policy: for every token-intensive task, your orchestrator model (Claude Fable, Claude Opus, Copilot — whatever you run) writes a full implementation plan, hands it to a cheap open-weight worker, and reviews the result before anything lands. You don't ask for it each time — planning expensive and typing cheap becomes how the model works.

- 🧠 **Orchestrator** — plans the task, writes the work order, reviews the diff, runs the tests, owns git
- ⌨️ **Workers** — Kimi K3, GLM 5.2, DeepSeek V4 running as headless Claude Code sessions via OpenRouter
- 🔑 **One key** — everything routes through OpenRouter; no Moonshot/Z.ai/DeepSeek accounts needed

| Worker | Model | $/M tokens (in / out) | Good for |
|---|---|---|---|
| `kimi` | moonshotai/kimi-k3 | $3.00 / $15.00 | Hardest tasks, long refactors |
| `glm` | z-ai/glm-5.2 | $0.97 / $3.06 | Balanced default, frontend |
| `deepseek` | deepseek/deepseek-v4-pro | $0.44 / $0.87 | Well-specified backend work |
| `flash` | deepseek/deepseek-v4-flash | $0.10 / $0.20 | Trivial mechanical edits |

*(Prices: OpenRouter, July 2026 — check current rates.)*

## Requirements

- [Claude Code CLI](https://claude.com/claude-code) installed (`claude --version`) — it's the worker runtime, needed even if your orchestrator is Copilot
- An [OpenRouter](https://openrouter.ai) account with an API key and a few dollars of credits

## Install

### Claude Code — as a plugin (recommended)

```bash
claude plugin marketplace add ferduque/model-router
claude plugin install model-router@model-router
```

(or `/plugin marketplace add ferduque/model-router` then `/plugin install` inside Claude Code)

The plugin ships a **SessionStart hook** that injects the plan→delegate→review policy into every session — that's what makes it the default behavior instead of a skill the model may or may not consult. Then create your key file:

```bash
mkdir -p ~/.model-router && curl -fsSL https://raw.githubusercontent.com/ferduque/model-router/main/env.example -o ~/.model-router/env
```

Open `~/.model-router/env`, replace the placeholder with your OpenRouter API key, restart Claude Code.

### Copilot / bare skill (no plugin support)

```bash
curl -fsSL https://raw.githubusercontent.com/ferduque/model-router/main/install.sh | bash
```

Installs the skill into `~/.copilot/skills/` and `~/.claude/skills/` and creates the key file. Copilot also accepts `copilot skill add https://github.com/ferduque/model-router`. Since Copilot has no session hooks, add the rule from ["Make it the guaranteed default"](#make-it-the-guaranteed-default) to `.github/copilot-instructions.md` or `AGENTS.md`.

**Mac, no terminal:** download this repo (green **Code** button → Download ZIP), unzip, double-click `Setup Model Router.command`. It installs the bare skill and opens the key file for you to paste into.

## Use

Nothing to invoke — ask for work as you normally would:

> "Build the settings page from the spec in docs/settings.md"

The orchestrator plans the task in full, picks the cheapest worker that can survive it (announcing which and why), spawns it, reads the diff, runs your tests, and retries or takes over if the worker fails twice. Naming a worker ("have **kimi** do it") or saying "do it yourself" always overrides the default. Workers can't commit, can't run arbitrary commands, and never see your API keys.

Trivial edits, design decisions, and security-critical code are never delegated — briefing a worker for a 3-line change costs more than the change.

### Make it the guaranteed default

**Plugin users are done** — the SessionStart hook already injects the policy into every session. Only two setups need a rule in an always-loaded instructions file: Copilot (`.github/copilot-instructions.md` or `AGENTS.md`) and bare-skill Claude Code installs (`~/CLAUDE.md`):

```
Cost policy: for token-intensive implementation work, follow the
model-router skill by default — plan fully, delegate implementation to a
cheap worker, review the result. Don't ask permission to delegate.
```

## How it works

OpenRouter exposes an [Anthropic-compatible endpoint](https://openrouter.ai/docs/cookbook/coding-agents/claude-code-integration), so a headless Claude Code process (`claude -p`) can run with any hosted model as its brain:

```
you ──> orchestrator (frontier model, your existing plan)
              │  brief.md
              ▼
         claude -p  ── ANTHROPIC_BASE_URL=https://openrouter.ai/api ──> worker model
              │
              ▼
         git diff ──> orchestrator reviews, tests, ships
```

Worker tokens bill to your OpenRouter credits; the orchestrator stays on whatever plan you already pay for.

## Safety defaults

- Workers run with `--permission-mode acceptEdits` — file edits only, no arbitrary shell
- Hooks disabled inside worker sessions (your auto-commit/format hooks won't fire on unreviewed code)
- Orchestrator owns git; briefs never contain secrets
- Never uses `--dangerously-skip-permissions`

## Credits

Pattern inspired by [david-internal/kimi-router](https://github.com/david-internal/kimi-router) (single-model version of this idea). Built on the open [Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) format.

## License

MIT
