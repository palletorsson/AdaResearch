# `data/chamber/`

Auto-improvement loop for artifacts. Every iteration produces a self-contained,
portable, replayable record. The repo's `dev` branch never sees rejected ideas.

> **Spec:** see [`doc/CHAMBER_PROPOSAL_FORMAT.md`](../../doc/CHAMBER_PROPOSAL_FORMAT.md)
> **Tool:** `python tools/chamber.py` — see `--help` for subcommands

## Subdirectories

| Dir | Status | What's here |
|---|---|---|
| `draft/<artifact>/<timestamp>/` | in-progress | proposals being worked on |
| `approved/<artifact>/<timestamp>/` | accepted | proposals ready to apply (verbatim or via prompt re-run) |
| `rejected/<artifact>/<timestamp>/` | declined | proposals that didn't work + a `reason.md` explaining why |

## Why three states (not just "applied")

The chamber doesn't auto-commit accepted proposals. **Approved means "ready to
apply when you choose"**, not "applied." This separates judgment from action:

- A proposal can be approved on the workstation but not applied until the
  next session
- The same approved proposal can be re-applied later if a refactor breaks
  the original code (just `git apply changes.patch` again)
- Approved proposals are queryable as a roadmap: *what improvements have we
  greenlit but not yet shipped?*

## Why keep the rejected ones

Rejected ≠ deleted. The rejected directory is **negative training data**.
Each entry preserves:
- The original prompt (so future sessions don't re-propose the same thing)
- The patch that didn't work (so we can see HOW it was wrong, not just that it was)
- A `reason.md` (the WHY)
- The before/after captures (the visual evidence)

Patterns in rejection reasons surface what categories of proposal don't fit
this project — gold for skill-evolution and prompt-calibration over time.

## Each iteration's contents

```
proposal.md           the prompt — what we're trying to achieve (durable spec)
changes.patch         git diff of the worktree — exactly what code changed
context_bundle.json   what the artifact looked like before reasoning started
meta.json             timestamps, status, claude version, rating, decision
before/               4 PNG captures from the original artifact
after/                4 PNG captures from the speculative apply
reason.md             only in rejected/ — the why
```
