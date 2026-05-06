# `approved/`

Proposals the user accepted. Each is **ready to apply when desired** — the
chamber doesn't auto-commit; approval and application are two steps so the
queue of approved improvements is itself a planning artifact.

To apply an approved proposal:

```bash
# verbatim (deterministic)
git apply data/chamber/approved/<artifact>/<timestamp>/changes.patch

# OR via the prompt (fresh interpretation, may differ)
/ada-artifact-improver <artifact> --proposal=data/chamber/approved/<artifact>/<timestamp>/proposal.md
```

Approved proposals can be re-applied later if a future refactor breaks the
original code — the patch may not apply cleanly, but the prompt remains a
valid spec.
