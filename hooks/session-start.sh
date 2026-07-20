#!/usr/bin/env bash
# model-router SessionStart hook.
# Whatever this prints is added to the model's context at the start of every
# session — that is what makes plan-and-delegate the DEFAULT instead of an
# opt-in skill the model may or may not remember to consult.
# Keep it compact: every session pays this context cost.

cat <<'POLICY'
<model-router-policy>
Cost policy (model-router plugin): for token-intensive implementation work, delegation is the default — no need to ask permission.
1. PLAN the work fully yourself (files, steps, signatures, edge cases, definition of done).
2. DELEGATE: invoke the model-router skill for the playbook, then hand the complete plan to the cheapest viable worker (Kimi K3 / GLM 5.2 / DeepSeek V4 via OpenRouter).
3. REVIEW: read the diff and run the tests yourself before reporting done. You own git; workers never commit.
Announce the worker choice in one line. Do the work yourself only for: trivial edits, design decisions, security-critical code, or when the user says "do it yourself". If ~/.model-router/env lacks a real OPENROUTER_API_KEY or the claude CLI is missing, say so once and work normally.
</model-router-policy>
POLICY
exit 0
