# `rejected/`

Proposals that didn't work. **Kept on purpose** — these are the chamber's
negative training data.

Each entry contains everything the approved/ entries do, plus a `reason.md`
explaining why the proposal failed:

| Tag | Meaning |
|---|---|
| `visual-cluttered` | the change broke readability, too much going on |
| `curriculum-broken` | used a technique not yet unlocked at this sequence |
| `performance-cost` | works but tanked framerate / draw calls |
| `concept-mismatch` | technically applied but missed the @identity essence |
| `already-tried` | duplicate of an earlier rejection — flag a dead-end pattern |
| `needs-other-system` | requires infrastructure that isn't built yet |

When proposing improvements, future sessions should grep this dir first.
A rejected attempt at an artifact is a strong signal not to retry the same
direction without explicitly addressing what failed.
