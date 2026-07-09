---
name: orchestrate-codex
description: Recommended working mode for substantial, multi-step work — one agent (Claude) orchestrates, owns the plan/source-of-truth, and verifies; Codex executes well-scoped, disjoint work units via `codex exec`. Use by default for refactors, multi-file features, audits, migrations, or any parallelizable task. Skip for trivial one-offs (just do those directly). Keywords: orchestrate, drive codex, executor mode, orchestrator, codex exec.
---

# Orchestrate + Codex (orchestrator/executor working mode)

When both Claude Code and the Codex CLI (`codex`) are available, the most reliable,
highest-throughput pattern for substantial work is **one orchestrator + Codex as
executor**, not two free-roaming agents on the same tree (which corrupt each other's
work).

## Roles

- **Orchestrator (Claude)** — owns the **single source of truth** (the project's
  planning/tracking state: the task tracker, plan docs, decision log). Decomposes the
  work into disjoint units, dispatches each to an executor, **verifies the result with
  evidence**, integrates conclusions back into the plan, and commits.
- **Executor (Codex)** — runs **one well-scoped unit at a time** on a **disjoint set of
  files**, and reports back. The executor never edits the plan/source-of-truth — it
  proposes; the orchestrator integrates.

## Coordination rules (non-negotiable — corruption-avoidance)

1. **One writer on the source of truth.** Only the orchestrator edits the plan/tracking
   docs. The executor reports; the orchestrator integrates. Two writers race and clobber.
2. **Disjoint file units.** Two agents must never edit the same file concurrently. Scope
   each unit to a non-overlapping set of files. Use a git branch per unit if units might
   touch nearby code.
3. **One owner of the running stack/DB.** Whoever runs the app/DB/tests owns it; the other
   doesn't start conflicting services (same ports / same DB).
4. **Verify before "done".** Executors are optimistic ("production-ready"). Never accept a
   self-report. The orchestrator re-runs the real checks and reviews the diff itself
   (author ≠ approver).

## Dispatching Codex (`codex exec`)

Codex runs **non-interactively** with `codex exec`. The reliable pattern: **write the
brief to a scratch file**, pipe it on **stdin** (avoids shell-escaping pain — briefs have
backticks/quotes/paths), run in the **background**, and capture the final message to a file.

```bash
codex exec -o /tmp/codex-out.md - < /path/to/brief.txt   # then read /tmp/codex-out.md
```

### Key flags (`codex exec`)

| Flag | Use |
|---|---|
| `-s, --sandbox <mode>` | `read-only` (analysis/plans), `workspace-write` (edit repo, bounded), `danger-full-access` (no FS sandbox) |
| `--dangerously-bypass-approvals-and-sandbox` | **YOLO** — no approvals, no sandbox (see below) |
| `-m, --model <model>` | override the configured model |
| `-c model_reasoning_effort="high"` | **thinking depth** — `minimal`/`low`/`medium`(default)/`high` |
| `-c <key>=<value>` | override any `config.toml` value (TOML, dotted path) |
| `-o, --output-last-message <FILE>` | write Codex's final message to a file (clean capture) |
| `--json` | stream events as JSONL (machine-readable progress) |
| `--output-schema <FILE>` | force the final response to a JSON Schema (structured result) |
| `-C, --cd <DIR>` · `--add-dir <DIR>` | working root · extra writable dirs |
| `--ephemeral` | don't persist the session to disk |
| `codex exec resume --last` | continue the most recent session (iterate) |

### Sandbox modes & "yolo"

Prefer the **sandboxed modes** (`-s read-only` for analysis, `-s workspace-write` for bounded
edits) when they work — they are the safer default.

**But sandboxing relies on bubblewrap, which fails in unprivileged / nested containers**
(`bwrap: No permissions to create a new namespace`). Codex then can't even read files and
(with hooks on) can loop forever. In such an environment:

- **Use `--dangerously-bypass-approvals-and-sandbox` (YOLO)** — it skips bubblewrap entirely
  (no namespace needed), so it actually runs.
- **Only do this when the environment is *already externally sandboxed*** (an isolated
  container cut off from the host and your other projects). The **safety net is then git +
  the container, not Codex's own sandbox**: start from a **clean / committed working tree** so
  `git` is the undo, and the orchestrator **reviews the diff** before accepting. Never yolo on
  top of valuable uncommitted work.
- **Add `--disable hooks`** for non-interactive runs if a Stop/notify hook traps `codex exec`
  in a post-completion loop (common with oh-my-codex headless) → clean exit.

### Reasoning effort ("thinking mode")

Override per run: `-c model_reasoning_effort="high"` for deep design / tricky debugging; keep
`low`/`medium` for mechanical or quick units (faster, cheaper).

### Recommended invocations

- **Plan / investigate** (deep reasoning; tell it "do not edit, report only" in the brief):
  `codex exec -s read-only -c model_reasoning_effort="high" -o out.md - < brief.txt`
  (or add `--dangerously-bypass-approvals-and-sandbox --disable hooks` if sandboxing is broken)
- **Implement a unit** (clean git tree first; review the diff after):
  `codex exec -s workspace-write -o out.md - < brief.txt`

Run in the background, **read `out.md`** for the final answer, and **monitor**: kill a run that
loops/hangs with `pkill -f 'codex exec'`. Under yolo there is no sandbox, so a read-only-*intent*
task is enforced only by the brief — say "report only, edit nothing" and verify it didn't.

> If Codex runs oh-my-codex with multi-agent enabled, one `codex exec` may itself fan out
> internally. Mark the project `trusted` so it won't prompt.

## The brief template

Give Codex a tightly-scoped unit:
- **Context** + the **hard constraints** it must respect (don't make it re-litigate
  decisions already made).
- **What to investigate**, asking it to **cite file:line** (grounds the work in real code).
- **The deliverable** (a plan, or a concrete change + which files).
- **"Do NOT touch the plan/source-of-truth — report back, the orchestrator integrates."**
- **Test/verification expectations** consistent with the repo's conventions.

## Verify before "done" (orchestrator)

- Re-run the relevant test suites **yourself** (fresh fixtures/DB where the repo requires it).
- **Read the diff** for design soundness; don't trust the summary. Run a separate reviewer
  pass (e.g. the `code-reviewer` agent) for risky/revenue-touching changes.
- For UI/flow behaviour, drive the real app (headless browser) rather than hand-rolled
  curl/Playwright.

## Integrate + commit (orchestrator)

- Fold the executor's verified conclusions into the plan/tracking docs (you are the single
  writer). Record open follow-ups explicitly so nothing is lost.
- Commit in **atomic, conventional** units, one commit per logical unit. Respect the repo's
  commit conventions (some repos strip AI-attribution trailers — don't fight the hooks).

## When NOT to use this

- Trivial one-offs, single-file edits, quick lookups → just do them directly; spinning up an
  executor is overhead.
- When you need a second *model's perspective* rather than execution → `omc ask codex` /
  `ccg` (advisory) is the lighter tool.
