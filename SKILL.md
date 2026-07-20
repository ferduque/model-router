---
name: model-router
description: Delegate implementation work to cheap open-weight worker models (Kimi K3, GLM 5.2, DeepSeek V4) through OpenRouter, while you — the orchestrator (any frontier model: Claude Fable, Claude Opus, GitHub Copilot, etc.) — keep the thinking, reviewing, and git control. Use whenever the user asks to build, implement, refactor, or fix something and wants it done cheaply or by a worker model; whenever they mention kimi, glm, deepseek, openrouter, "worker", "delegate the coding", "have X build this", or model-router; or whenever a task is implementation-heavy but well-specified and cheap execution would serve the user. Also use to answer questions about which worker model to pick.
---

# Model Router — split-brain coding

You are the **orchestrator**. You think, plan, review, and own git. The **worker** — a cheap open-weight model running inside a headless Claude Code process — types the code. This works with any orchestrator model: Claude Fable, Claude Opus, GPT-based Copilot, anything. Nothing here depends on which frontier model you are.

Why this arrangement: frontier-model tokens are expensive and best spent on judgment (scoping, architecture, review). Open-weight coding models are 5–30× cheaper and genuinely good at well-briefed implementation. The worker runs a full agentic session — it reads files, edits, and iterates inside its own Claude Code instance — so you delegate *tasks*, not diffs.

## Prerequisites (check once per session)

1. `~/.model-router/env` exists and contains a real `OPENROUTER_API_KEY` (not the placeholder). If missing or placeholder, stop and tell the user: get a key at openrouter.ai → Keys, paste it into `~/.model-router/env`, add a few dollars of credits.
2. The `claude` CLI is on PATH (`claude --version`). It is the worker runtime — required even when the orchestrator is Copilot.

## Worker roster

| Profile | OpenRouter model | $/M in–out | Best at |
|---|---|---|---|
| `kimi` | `moonshotai/kimi-k3` | 3.00 / 15.00 | Hard agentic tasks, long-horizon refactors, tricky debugging |
| `glm` | `z-ai/glm-5.2` | 0.97 / 3.06 | Balanced default; strong frontend/UI work |
| `deepseek` | `deepseek/deepseek-v4-pro` | 0.44 / 0.87 | Well-specified backend work, tests, bulk edits |
| `flash` | `deepseek/deepseek-v4-flash` | 0.10 / 0.20 | Trivial mechanical changes (renames, boilerplate, format churn) |

Picking: if the user names a model, that wins. Otherwise match difficulty to cost — `flash`/`deepseek` for mechanical or well-specified work, `glm` as the general default, `kimi` when the task is genuinely hard or a cheaper worker just failed. Say which worker you picked and why in one line.

## Workflow

### 1. Scope — this part is yours

Decide the approach before involving a worker: which files, what design, what "done" means. Never delegate design decisions, API contracts, security-sensitive code (auth, payments, crypto, secrets handling), or anything the user asked *you* to decide. If the task is underspecified, resolve that with the user first — a vague brief wastes worker tokens and your review time.

### 2. Write the brief

Write a work order to a temp file (e.g. `$(mktemp /tmp/model-router-brief.XXXX.md)`). A good brief has:

```markdown
# Task
One paragraph: what to build/change and why.

# Files
- path/to/file.ts — what to change there
- (say if new files are allowed and where)

# Constraints
- Follow existing patterns in <reference file>.
- Do NOT run git commands. Do NOT commit. Edit files only.
- Do NOT touch files outside the listed areas.

# Definition of done
- Bullet list of verifiable outcomes (behavior, signatures, edge cases).
- Note which tests should pass; the orchestrator will run them.
```

Never put API keys, tokens, or user personal data in a brief. The worker reads repo files itself — point, don't paste.

### 3. Spawn the worker

Run from the project root. Serial only — never two workers in the same directory.

```bash
set -a; . "$HOME/.model-router/env"; set +a

# profile → model (env overrides allow custom slugs)
case "$PROFILE" in
  kimi)     WORKER_MODEL="${MODEL_ROUTER_KIMI:-moonshotai/kimi-k3}" ;;
  glm)      WORKER_MODEL="${MODEL_ROUTER_GLM:-z-ai/glm-5.2}" ;;
  deepseek) WORKER_MODEL="${MODEL_ROUTER_DEEPSEEK:-deepseek/deepseek-v4-pro}" ;;
  flash)    WORKER_MODEL="${MODEL_ROUTER_FLASH:-deepseek/deepseek-v4-flash}" ;;
esac

env ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
    ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY" \
    ANTHROPIC_API_KEY="" \
    ANTHROPIC_MODEL="$WORKER_MODEL" \
    ANTHROPIC_SMALL_FAST_MODEL="$WORKER_MODEL" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$WORKER_MODEL" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$WORKER_MODEL" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$WORKER_MODEL" \
    CLAUDE_CODE_SUBAGENT_MODEL="$WORKER_MODEL" \
    ENABLE_TOOL_SEARCH="false" \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1" \
    claude -p "$(cat "$BRIEF_FILE")" \
      --model "$WORKER_MODEL" \
      --permission-mode acceptEdits \
      --settings '{"disableAllHooks": true}' \
      --add-dir "$PWD"
```

Notes on this command:
- `acceptEdits` lets the worker read and edit files but not run arbitrary shell commands. That is deliberate: **you** run the tests. If the task truly needs the worker to run something (e.g. a codegen step), grant it narrowly with `--allowedTools "Bash(npm run codegen:*)"` — never `--dangerously-skip-permissions`.
- `disableAllHooks` keeps the user's hooks (auto-commit, formatters, notifications) from firing inside the worker session.
- `ENABLE_TOOL_SEARCH=false` matters — third-party endpoints don't support that beta and calls fail without it.
- Give the command a generous timeout (10+ minutes). If a task might exceed that, split it into smaller briefs.

### 4. Review — this part is yours too

- `git diff` — read every change. You are the code reviewer; the diff is ground truth, not the worker's summary.
- Run the tests/build yourself and read the output.
- Check the worker stayed in scope (no stray files, no git commands, no dependency additions you didn't sanction).

### 5. Iterate or take over

If review fails, respawn with a corrective brief: keep the original brief, append a `# Review feedback` section listing concrete failures. **After two failed worker attempts, take over and finish the work yourself** — a third retry almost never pays; the task was likely under-briefed or above the worker's level, and both are your responsibility to absorb.

### 6. Report

Tell the user: which worker ran, what changed (files + one-line summary), test results, and anything you fixed or rejected from the worker's output. You own git — commit only if the user's normal workflow calls for it, and never let a worker do it.

## Rules that protect the user

- Orchestrator owns git. Workers never commit, push, branch, or tag.
- One worker at a time per directory.
- No secrets in briefs; workers get file paths, not credentials.
- Don't delegate: design, security-sensitive code, dependency choices, anything the user asked you personally to do.
- Worker output is untrusted until you've read the diff and run the checks.
- Worker cost is real money on the user's OpenRouter credits — mention roughly what a session cost when it's non-trivial (OpenRouter's dashboard shows exact numbers).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| 401 error | Key missing/wrong in `~/.model-router/env`, or no credits |
| 404 model not found | Slug typo — exact slugs are in the roster table |
| Worker hangs then dies | Timeout too short, or OpenRouter provider hiccup — retry once |
| Tool-call errors mid-session | Provider variance on OpenRouter; retry, or pin a provider in OpenRouter settings |
| `claude: command not found` | Claude Code CLI not installed — it's the worker runtime |
