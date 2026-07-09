---
name: orchestrate-codex
description: Recommended working mode for substantial, multi-step work in this devcontainer — one agent (Claude) orchestrates, owns the plan/source-of-truth, and verifies; Codex executes well-scoped, disjoint work units via `codex exec`. Use by default for refactors, multi-file features, audits, migrations, or any parallelizable task. Skip for trivial one-offs (just do those directly). Keywords: orchestrate, drive codex, executor mode, orchestrator, codex exec.
---

# Orchestrate + Codex (orchestrator/executor working mode)

The devcontainer bundles both Claude Code and the Codex CLI (`codex`, ChatGPT-auth
persisted in `.devcontainer/.codex-data/`). For substantial work the most reliable,
highest-throughput pattern is **one orchestrator + Codex as executor**, not two
free-roaming agents on the same tree (which corrupt each other's work).

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

Codex runs **non-interactively** with `codex exec` (tmux-based runners like OMC teams are
unavailable here). The reliable pattern: **write the brief to a scratch file**, pipe it on
**stdin** (avoids shell-escaping pain — briefs have backticks/quotes/paths), run in the
**background**, and capture the final message to a file.

```bash
cd /workspaces/brume
# In THIS devcontainer the sandboxed modes fail (see below) → yolo + disable hooks:
codex exec --dangerously-bypass-approvals-and-sandbox --disable hooks \
  -o /tmp/codex-out.md - < /path/to/brief.txt   # then read /tmp/codex-out.md
```

### Key flags (`codex exec`)

| Flag | Use |
|---|---|
| `-s, --sandbox <mode>` | `read-only` (analysis/plans), `workspace-write` (edit repo, bounded), `danger-full-access` (no FS sandbox) |
| `--dangerously-bypass-approvals-and-sandbox` | **YOLO** — no approvals, no sandbox (see below) |
| `-m, --model <model>` | override the configured model (currently `gpt-5.5` in `~/.codex/config.toml`) |
| `-c model_reasoning_effort="high"` | **thinking depth** — `minimal`/`low`/`medium`(default)/`high` |
| `-c <key>=<value>` | override any `config.toml` value (TOML, dotted path) |
| `-o, --output-last-message <FILE>` | write Codex's final message to a file (clean capture) |
| `--json` | stream events as JSONL (machine-readable progress) |
| `--output-schema <FILE>` | force the final response to a JSON Schema (structured result) |
| `-C, --cd <DIR>` · `--add-dir <DIR>` | working root · extra writable dirs |
| `--ephemeral` | don't persist the session to disk |
| `codex exec resume --last` | continue the most recent session (iterate) |

### Sandbox modes & "yolo" — IN THIS DEVCONTAINER, use yolo (verified 2026-06-23)

**The sandboxed modes (`-s read-only`, `-s workspace-write`) DO NOT WORK here.** They rely on
bubblewrap, which fails inside this unprivileged / nested devcontainer with
`bwrap: No permissions to create a new namespace`. Codex then can't even read files and (with
hooks on) loops forever. So, here:

- **Use `--dangerously-bypass-approvals-and-sandbox` (YOLO)** — it skips bubblewrap entirely
  (no namespace needed), so it actually runs. Verified: Codex reads/edits + exits cleanly.
  This is the **required** mode in this devcontainer, not just an option.
- **Why it's safe here:** Codex's own help calls yolo "intended solely for environments that
  are externally sandboxed" — **this devcontainer IS that environment**: isolated from the
  host (the host docker socket was removed in DEC-016, so Codex can't reach the host daemon or
  your other projects). The **safety net is git + the container, not Codex's sandbox**: start
  from a **clean / committed working tree** so `git` is the undo, and the orchestrator
  **reviews the diff** before accepting. Never yolo on top of valuable uncommitted work.
- **Always add `--disable hooks`** for non-interactive runs: the bundled oh-my-codex "Stop"
  hook otherwise traps `codex exec` in a post-completion loop (it keeps demanding a stop
  condition it can't satisfy headless). Verified: `--disable hooks` → clean exit.
- (On a *non-nested* host where bubblewrap works, `-s read-only` / `workspace-write` would be
  the safer first choice. Not here.)

### Reasoning effort ("thinking mode")

Default `medium` (`~/.codex/config.toml`). Override per run: `-c model_reasoning_effort="high"`
for deep design / tricky debugging; keep `low`/`medium` for mechanical or quick units (faster,
cheaper).

### Recommended invocations (this devcontainer → always yolo + `--disable hooks` + `-o`)

- **Plan / investigate** (deep reasoning; tell it "do not edit, report only" in the brief):
  `codex exec --dangerously-bypass-approvals-and-sandbox --disable hooks -c model_reasoning_effort="high" -o out.md - < brief.txt`
- **Implement a unit** (clean git tree first; review the diff after):
  `codex exec --dangerously-bypass-approvals-and-sandbox --disable hooks -o out.md - < brief.txt`

Run in the background, **read `out.md`** for the final answer, and **monitor**: kill a run that
loops/hangs with `pkill -f 'codex exec'` (don't let it spin). Because yolo has no sandbox, a
read-only-*intent* task is enforced only by the brief — say "report only, edit nothing" and
verify it didn't.

> Codex here runs oh-my-codex with multi-agent enabled, so one `codex exec` may itself fan
> out internally; the project is marked `trusted` so it won't prompt for trust.

## The brief template

Give Codex a tightly-scoped unit:
- **Context** + the **hard constraints** it must respect (don't make it re-litigate
  decisions already made).
- **What to investigate**, asking it to **cite file:line** (grounds the work in real code).
- **The deliverable** (a plan, or a concrete change + which files).
- **"Do NOT touch the plan/source-of-truth dossier — report back, the orchestrator
  integrates."**
- **Test/verification expectations** consistent with this repo (see below).
- For implementation: which tests to add/run, on a **fresh `brume_test` DB**.

## Verify before "done" (orchestrator)

- Re-run the relevant suites **yourself** on a **fresh `brume_test`** (testcontainers needs
  the host docker socket, which is absent here → set
  `TEST_DATABASE_URL=postgresql://brume:brume@postgres:5432/brume_test` and the matching
  `TEST_DATABASE_DIRECT_URL`; recreate the DB first via asyncpg on `.../postgres`).
  Reference EE baseline: `make test-ee` ≈ **320 passed / 9 skipped** with billing OFF.
- **Read the diff** for design soundness; don't trust the summary. Run a separate
  reviewer pass (e.g. the `code-reviewer` agent) for risky/revenue-touching changes.
- For UI/flow behaviour, drive the real app via `gstack`/`browse` (see the repo testing
  rule) — not hand-rolled curl/Playwright.

## Integrate + commit (orchestrator)

- Fold the executor's verified conclusions into the plan/tracking docs (you are the single
  writer). Record open follow-ups explicitly so nothing is lost.
- Commit in **atomic, conventional** units. **No AI-attribution trailers** (the `commit-msg`
  hook strips them; `pre-push` blocks them). One commit per logical unit.

## When NOT to use this

- Trivial one-offs, single-file edits, quick lookups → just do them directly; spinning up an
  executor is overhead.
- When you need a second *model's perspective* rather than execution → `omc ask codex` /
  `ccg` (advisory) is the lighter tool.
