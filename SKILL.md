---
name: model-router
description: Cost-optimizing DEFAULT for all implementation work, not an opt-in tool. You — the orchestrator (any frontier model: Claude Fable, Claude Opus, GitHub Copilot, etc.) — plan and review; cheap open-weight workers (Kimi K3, GLM 5.2, DeepSeek V4, via one OpenRouter key) type the code. Invoke for ANY token-intensive task — features, refactors, test suites, migrations, boilerplate, multi-file or many-line edits — even when the user never mentions workers, models, or cost: delegating is the standing policy. Also invoke when the user mentions kimi, glm, deepseek, openrouter, worker models, or asks who should implement something. Skip only for trivial edits, pure design/advice, or security-critical code.
---

# Model Router — plan expensive, type cheap

You are the **orchestrator**. Your tokens cost 10–100× what worker tokens cost, so your job is the judgment work: scoping, planning, reviewing, owning git. The **workers** — open-weight models running inside headless Claude Code processes — do the typing. This holds for any orchestrator model: Claude Fable, Claude Opus, GPT-based Copilot, anything.

**This is the default operating mode, not a feature the user must request.** When an implementation task arrives, the question is not "should I delegate?" but "is there any reason not to?". Don't ask the user for permission to delegate — announce in one line which worker you picked and why. If the user says "do it yourself", that always wins.

## The delegation decision

**Delegate (the default)** whenever the implementation is token-intensive and you can specify it fully: new features, refactors, test suites, migrations, boilerplate, multi-file changes, anything beyond roughly 20–30 lines of writing. Rule of thumb: if you can write a complete plan for it, a worker can implement it.

**Do it yourself (the exceptions)** when:
- The edit is trivial — writing the brief would cost more than the change itself.
- The task is design, advice, debugging-by-thinking, or conversation — no bulk typing to save on.
- The code is security-critical (auth, payments, crypto, secrets handling) or the user asked *you* personally to write it.
- Two worker attempts have already failed — a third retry almost never pays.

Mixed tasks split: you make the design decisions and edit the delicate file yourself; the worker builds the twenty files around it.

## Prerequisites (check once per session)

1. `~/.model-router/env` exists and contains a real `OPENROUTER_API_KEY` (not the placeholder). If missing or placeholder, tell the user: get a key at openrouter.ai → Keys, paste it into `~/.model-router/env`, add a few dollars of credits. Then fall back to doing the work yourself this session — never block the user's task on the key.
2. The `claude` CLI is on PATH (`claude --version`). It is the worker runtime — required even when the orchestrator is Copilot. If absent, same fallback: tell the user, do the work yourself.

## Worker roster

| Profile | OpenRouter model | $/M in–out | Best at |
|---|---|---|---|
| `kimi` | `moonshotai/kimi-k3` | 3.00 / 15.00 | Hard agentic tasks, long-horizon refactors, tricky debugging |
| `glm` | `z-ai/glm-5.2` | 0.97 / 3.06 | Balanced default; strong frontend/UI work |
| `deepseek` | `deepseek/deepseek-v4-pro` | 0.44 / 0.87 | Well-specified backend work, tests, bulk edits |
| `flash` | `deepseek/deepseek-v4-flash` | 0.10 / 0.20 | Trivial mechanical changes (renames, boilerplate, format churn) |

Picking: if the user names a model, that wins. Otherwise pick the cheapest worker the task can survive: `flash` for mechanical churn, `deepseek` for anything you've specified tightly, `glm` when there's moderate judgment left in the execution, `kimi` only when the task is genuinely hard or a cheaper worker just failed. The better your plan, the cheaper the worker you can afford — thorough planning is literally what saves the money.

## Workflow

### 1. Plan — this is where your tokens go

Produce a **complete implementation plan** before spawning anything: approach, files to touch, function signatures, data shapes, edge cases, what "done" means, which tests prove it. The worker executes your plan; it should never have to make a design decision. An underspecified brief doesn't save cost — it buys a bad diff you'll pay to review and redo.

If requirements are unclear, resolve that with the user first.

### 2. Write the brief — the full plan, not a wish

Write the work order to a temp file (e.g. `$(mktemp /tmp/model-router-brief.XXXX.md)`):

```markdown
# Task
One paragraph: what to build/change and why.

# Plan
The complete implementation plan — steps in order, per-file changes,
signatures, edge cases. The worker follows this; it does not redesign it.

# Files
- path/to/file.ts — what changes there
- (say if new files are allowed and where)

# Constraints
- Follow existing patterns in <reference file>.
- Do NOT run git commands. Do NOT commit. Edit files only.
- Do NOT touch files outside the listed areas.
- If part of the plan is impossible as written, stop and say so in your
  final message instead of improvising a different design.

# Definition of done
- Verifiable outcomes (behavior, signatures, edge cases).
- Which tests should pass; the orchestrator will run them.
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
- Give the command a generous timeout (10+ minutes). If a task might exceed that, split the plan into smaller briefs and run them in sequence.
- While the worker runs, don't idle-narrate; prepare the review (which tests you'll run, what you expect the diff to contain).

### 4. Review — the other place your tokens go

- `git diff` — read every change. You are the code reviewer; the diff is ground truth, not the worker's summary.
- Run the tests/build yourself and read the output.
- Check the worker stayed in scope and on plan (no stray files, no git commands, no dependency additions or design swaps you didn't sanction).

### 5. Iterate or take over

If review fails, respawn with a corrective brief: original brief + a `# Review feedback` section listing concrete failures. **After two failed worker attempts, take over and finish the work yourself** — the task was under-planned or above the worker's level, and both are yours to absorb. Consider one retry on the next worker up (`deepseek` → `glm` → `kimi`) before concluding that.

### 6. Report

Tell the user: which worker ran, what changed (files + one-line summary), test results, and anything you fixed or rejected from the worker's output. When a session was non-trivial, mention the rough worker cost — it's the point of the whole arrangement (OpenRouter's dashboard has exact numbers). You own git — commit only if the user's normal workflow calls for it, and never let a worker do it.

## Rules that protect the user

- Orchestrator owns git. Workers never commit, push, branch, or tag.
- One worker at a time per directory.
- No secrets in briefs; workers get file paths, not credentials.
- Don't delegate: design, security-sensitive code, dependency choices, anything the user asked you personally to do.
- Worker output is untrusted until you've read the diff and run the checks.
- Cost optimization never outranks correctness: if delegation is producing worse results on some task type, do that work yourself and say so.

## Making this automatic (setup hint)

Skills are consulted, not forced. To make plan-and-delegate the guaranteed default in every session, the user should add one rule to their always-loaded instructions file — `~/CLAUDE.md` or the project's `CLAUDE.md` for Claude Code; `.github/copilot-instructions.md` or `AGENTS.md` for Copilot:

> For token-intensive implementation work, follow the model-router skill by default: plan fully, delegate implementation to a cheap worker, review the result. Don't ask permission to delegate.

If you notice the user relies on this skill but has no such rule, suggest adding it once.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| 401 error | Key missing/wrong in `~/.model-router/env`, or no credits |
| 404 model not found | Slug typo — exact slugs are in the roster table |
| Worker hangs then dies | Timeout too short, or OpenRouter provider hiccup — retry once |
| Tool-call errors mid-session | Provider variance on OpenRouter; retry, or pin a provider in OpenRouter settings |
| `claude: command not found` | Claude Code CLI not installed — it's the worker runtime |
