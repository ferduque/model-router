# model-router

**Your frontier model thinks. Cheap open-weight models type.**

An [Agent Skill](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) for **Claude Code** and **GitHub Copilot** that lets your orchestrator model (Claude Fable, Claude Opus, Copilot — whatever you run) delegate implementation work to cheap open-weight workers, then review the result before anything lands.

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

### One-liner (Claude Code + Copilot, macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/ferduque/model-router/main/install.sh | bash
```

Then open `~/.model-router/env`, replace the placeholder with your OpenRouter API key, and restart your coding agent.

**Mac, no terminal:** download this repo (green **Code** button → Download ZIP), unzip, double-click `Setup Model Router.command`. It installs everything and opens the key file for you to paste into.

### Manual

1. Copy this folder to `~/.claude/skills/model-router/` (Claude Code) and/or `~/.copilot/skills/model-router/` (Copilot)
2. Copy `env.example` to `~/.model-router/env` and paste your OpenRouter key into it
3. Restart Claude Code / Copilot

GitHub Copilot also accepts: `copilot skill add https://github.com/ferduque/model-router`
For a single repo (any harness), drop the folder into `.github/skills/model-router/` instead.

## Use

Just ask, in your normal Claude Code or Copilot session:

> "Use model-router: have **glm** build the settings page from the spec in docs/settings.md"

> "Delegate this refactor to **deepseek**, review it, and run the tests"

> "Build this feature with the cheapest worker that can handle it"

The orchestrator writes a work order, spawns the worker, reads the diff, runs your tests, and retries or takes over if the worker fails twice. Workers can't commit, can't run arbitrary commands, and never see your API keys.

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
